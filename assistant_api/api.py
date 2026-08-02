import asyncio
import json
import logging
import os
import re
from datetime import date, datetime
from typing import Any
from urllib.parse import urlencode

import httpx


def load_local_env_file(path: str = ".env") -> None:
    if not os.path.exists(path):
        return

    with open(path, encoding="utf-8") as env_file:
        for line in env_file:
            stripped = line.strip()
            if not stripped or stripped.startswith("#") or "=" not in stripped:
                continue

            key, value = stripped.split("=", 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            if key and key not in os.environ:
                os.environ[key] = value


try:
    from dotenv import load_dotenv

    load_dotenv()
except ImportError:  # pragma: no cover - optional local convenience dependency
    load_local_env_file()

try:
    from openai import OpenAI
except ImportError:  # pragma: no cover - handled when DeepSeekGenerator is constructed
    OpenAI = None


logger = logging.getLogger(__name__)
logging.basicConfig(level=os.getenv("ASSISTANT_LOG_LEVEL", "INFO"))
DEEPSEEK_MODEL = os.getenv("DEEPSEEK_MODEL", "deepseek-v4-pro")
DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY", "")
SUPABASE_URL = os.getenv("SUPABASE_URL") or os.getenv("VITE_SUPABASE_URL", "")
SUPABASE_ANON_KEY = os.getenv("SUPABASE_ANON_KEY") or os.getenv("VITE_SUPABASE_ANON_KEY", "")
DEFAULT_HOLD_MINUTES = int(os.getenv("ASSISTANT_HOLD_MINUTES", "5"))
DEEPSEEK_TIMEOUT_SECONDS = float(os.getenv("DEEPSEEK_TIMEOUT_SECONDS", "45"))

REQUIRED_FIELDS = ("departure", "destination", "travel_date", "passenger_count")
CITY_PATTERN = r"[A-Za-z][A-Za-z\s.'-]{1,60}"


class AssistantError(Exception):
    def __init__(self, message: str, status: int = 400):
        super().__init__(message)
        self.status = status


def json_response(payload: dict[str, Any], status: int = 200) -> dict[str, Any]:
    return {
        "type": "http.response.start",
        "status": status,
        "headers": [
            (b"content-type", b"application/json; charset=utf-8"),
            (b"access-control-allow-origin", b"*"),
            (b"access-control-allow-headers", b"authorization, content-type"),
            (b"access-control-allow-methods", b"GET, POST, OPTIONS"),
        ],
        "body": json.dumps(payload, default=str).encode("utf-8"),
    }


async def send_json(send, payload: dict[str, Any], status: int = 200) -> None:
    response = json_response(payload, status)
    await send({key: value for key, value in response.items() if key != "body"})
    await send({"type": "http.response.body", "body": response["body"]})


async def read_body(receive) -> bytes:
    chunks = []
    while True:
        message = await receive()
        if message["type"] != "http.request":
            continue
        chunks.append(message.get("body", b""))
        if not message.get("more_body"):
            return b"".join(chunks)


def bearer_from_headers(headers: list[tuple[bytes, bytes]]) -> str:
    for key, value in headers:
        if key.lower() == b"authorization":
            raw = value.decode("utf-8")
            if raw.lower().startswith("bearer "):
                return raw[7:].strip()
    return ""


def normalize_text(value: Any) -> str:
    return str(value or "").strip()


def parse_positive_int(value: Any) -> int | None:
    try:
        parsed = int(value)
    except (TypeError, ValueError):
        return None
    return parsed if 1 <= parsed <= 9 else None


def parse_departure_datetime(travel_date: Any, departure_time: Any) -> datetime | None:
    date_text = normalize_text(travel_date)
    time_text = normalize_text(departure_time) or "00:00:00"

    try:
        parsed_date = datetime.strptime(date_text[:10], "%Y-%m-%d").date()
    except ValueError:
        return None

    time_parts = [part for part in time_text.split(":") if part != ""]
    try:
        hours = int(time_parts[0]) if len(time_parts) > 0 else 0
        minutes = int(time_parts[1]) if len(time_parts) > 1 else 0
        seconds = int(float(time_parts[2])) if len(time_parts) > 2 else 0
        return datetime(
            parsed_date.year,
            parsed_date.month,
            parsed_date.day,
            hours,
            minutes,
            seconds,
        )
    except (TypeError, ValueError):
        return None


def validate_departure_is_bookable(route: dict[str, Any], travel_date: Any, now: datetime | None = None) -> str:
    departure_at = parse_departure_datetime(travel_date, route.get("departure_time"))
    if not departure_at:
        return "Please provide the travel date in YYYY-MM-DD format."

    current_time = now or datetime.now()
    if departure_at <= current_time:
        return (
            f"{route_summary(route)} on {str(travel_date)[:10]} has already departed. "
            "Please choose a future travel date or another route."
        )

    return ""


def clear_invalid_travel_date(slots: dict[str, Any]) -> dict[str, Any]:
    next_slots = dict(slots)
    next_slots.pop("travel_date", None)
    return next_slots


def _parse_json_response(text: str, fallback: Any = None):
    if not text:
        return fallback

    fenced_match = re.search(r"```(?:json)?\s*(.*?)```", text, re.DOTALL)
    candidates = []
    if fenced_match:
        candidates.append(fenced_match.group(1).strip())

    object_match = re.search(r"\{.*\}", text, re.DOTALL)
    if object_match:
        candidates.append(object_match.group(0))

    array_match = re.search(r"\[.*\]", text, re.DOTALL)
    if array_match:
        candidates.append(array_match.group(0))

    candidates.append(text.strip())

    for candidate in candidates:
        try:
            return json.loads(candidate)
        except Exception:
            continue

    return fallback


class DeepSeekGenerator:
    def __init__(self):
        if OpenAI is None:
            raise RuntimeError("The openai package is required for DeepSeekGenerator.")
        if not DEEPSEEK_API_KEY or DEEPSEEK_API_KEY == "YOUR_DEEPSEEK_API_KEY":
            raise RuntimeError("DEEPSEEK_API_KEY is required for DeepSeekGenerator.")

        self.client = OpenAI(api_key=DEEPSEEK_API_KEY, base_url="https://api.deepseek.com")

    def generate_with_system(self, system_prompt, prompt, reasoning_effort="medium"):
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt},
        ]
        response = self.client.chat.completions.create(
            model=DEEPSEEK_MODEL,
            messages=messages,
            stream=False,
            timeout=DEEPSEEK_TIMEOUT_SECONDS,
            reasoning_effort=reasoning_effort,
            extra_body={"thinking": {"type": "enabled"}},
        )
        return response.choices[0].message.content

    def generate(self, prompt):
        return self.generate_with_system(
            "You are a helpful assistant for transportation ticket booking. "
            "Use the provided context to help passengers complete bookings accurately.",
            prompt,
        )

    def generate_json(self, system_prompt: str, prompt: str, fallback: Any = None, reasoning_effort="medium"):
        text = self.generate_with_system(system_prompt, prompt, reasoning_effort=reasoning_effort)
        return _parse_json_response(text, fallback=fallback)


def deepseek_diagnostics() -> dict[str, Any]:
    return {
        "api_key_configured": bool(DEEPSEEK_API_KEY and DEEPSEEK_API_KEY != "YOUR_DEEPSEEK_API_KEY"),
        "api_key_prefix": f"{DEEPSEEK_API_KEY[:5]}..." if DEEPSEEK_API_KEY else "",
        "model": DEEPSEEK_MODEL,
        "timeout_seconds": DEEPSEEK_TIMEOUT_SECONDS,
        "openai_package_installed": OpenAI is not None,
    }


def merge_slots(state: dict[str, Any], extracted: dict[str, Any]) -> dict[str, Any]:
    slots = dict(state.get("slots") or {})
    for key in REQUIRED_FIELDS:
        value = extracted.get(key)
        if key == "passenger_count":
            value = parse_positive_int(value)
        elif value is not None:
            value = normalize_text(value)
        if value:
            slots[key] = value
    return slots


def extract_with_regex(message: str) -> dict[str, Any]:
    text = normalize_text(message)
    extracted: dict[str, Any] = {}

    passenger_match = re.search(r"\b(?:for\s+)?(\d+)\s*(?:passengers?|people|tickets?|seats?)\b", text, re.I)
    if passenger_match:
        extracted["passenger_count"] = int(passenger_match.group(1))
    elif re.search(r"\b(one|single|solo)\s+(?:ticket|seat|passenger)\b", text, re.I):
        extracted["passenger_count"] = 1

    date_match = re.search(r"\b(20\d{2}-\d{2}-\d{2})\b", text)
    if date_match:
        extracted["travel_date"] = date_match.group(1)
    elif re.search(r"\btoday\b", text, re.I):
        extracted["travel_date"] = date.today().isoformat()

    route_match = re.search(
        rf"\bfrom\s+(?P<departure>{CITY_PATTERN})\s+(?:to|->|→)\s+(?P<destination>{CITY_PATTERN})\b",
        text,
        re.I,
    )
    if not route_match:
        route_match = re.search(
            rf"\b(?P<departure>{CITY_PATTERN})\s+(?:to|->|→)\s+(?P<destination>{CITY_PATTERN})\b",
            text,
            re.I,
        )

    if route_match:
        extracted["departure"] = route_match.group("departure").strip(" .")
        extracted["destination"] = route_match.group("destination").strip(" .")

    extracted["confirm"] = bool(re.search(r"\b(confirm|yes|yep|sure|book it|go ahead|looks good)\b", text, re.I))
    extracted["cancel"] = bool(re.search(r"\b(cancel|stop|nevermind|never mind)\b", text, re.I))
    return extracted


async def extract_with_deepseek(message: str, history: list[dict[str, Any]], state: dict[str, Any]) -> dict[str, Any]:
    if not DEEPSEEK_API_KEY or DEEPSEEK_API_KEY == "YOUR_DEEPSEEK_API_KEY":
        return extract_with_regex(message)

    system_prompt = (
        "Extract ticket booking intent as strict JSON. Keys: departure, destination, "
        "travel_date in YYYY-MM-DD, passenger_count as number, confirm boolean, cancel boolean. "
        "Use null for unknown values. Do not include prose."
    )
    fallback = extract_with_regex(message)
    prompt = json.dumps(
        {
            "known_slots": state.get("slots", {}),
            "recent_history": history[-8:],
            "latest_user_message": message,
        },
        default=str,
    )

    try:
        generator = DeepSeekGenerator()
        parsed = await asyncio.to_thread(
            generator.generate_json,
            system_prompt,
            prompt,
            fallback,
            "medium",
        )
    except Exception as error:
        logger.exception("DeepSeek extraction failed")
        raise AssistantError(f"DeepSeek is configured but could not be called: {error}", 502) from error

    if not isinstance(parsed, dict):
        parsed = fallback
    return {**fallback, **{key: value for key, value in parsed.items() if value not in (None, "")}}


class SupabaseTool:
    def __init__(self, user_token: str):
        if not SUPABASE_URL or not SUPABASE_ANON_KEY:
            raise AssistantError("Supabase environment is missing. Set SUPABASE_URL and SUPABASE_ANON_KEY.", 500)
        self.base_url = SUPABASE_URL.rstrip("/")
        self.headers = {
            "apikey": SUPABASE_ANON_KEY,
            "Authorization": f"Bearer {user_token or SUPABASE_ANON_KEY}",
            "Content-Type": "application/json",
        }

    async def _get(self, path: str, params: dict[str, str] | None = None) -> Any:
        url = f"{self.base_url}{path}"
        if params:
            url = f"{url}?{urlencode(params)}"
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.get(url, headers=self.headers)
        if response.status_code >= 400:
            raise AssistantError(response.text, response.status_code)
        return response.json()

    async def _post(self, path: str, payload: dict[str, Any]) -> Any:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(f"{self.base_url}{path}", headers=self.headers, json=payload)
        if response.status_code >= 400:
            raise AssistantError(response.text, response.status_code)
        return response.json()

    async def current_user(self) -> dict[str, Any] | None:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.get(f"{self.base_url}/auth/v1/user", headers=self.headers)
        if response.status_code >= 400:
            return None
        return response.json()

    async def current_profile(self, user_id: str) -> dict[str, Any] | None:
        rows = await self._get(
            "/rest/v1/profiles",
            {"select": "id,email,first_name,last_name,role", "id": f"eq.{user_id}", "limit": "1"},
        )
        return rows[0] if rows else None

    async def find_routes(self, departure: str, destination: str) -> list[dict[str, Any]]:
        params = {
            "select": "id,transport_type,departure,destination,departure_time,arrival_time,vehicles(id,vehicle_code,vehicle_type,capacity,deck_layout)",
            "departure": f"ilike.*{departure}*",
            "destination": f"ilike.*{destination}*",
            "order": "departure_time.asc",
        }
        return await self._get("/rest/v1/routes", params)

    async def seats_for_vehicle(self, vehicle_id: str) -> list[dict[str, Any]]:
        return await self._get(
            "/rest/v1/seats",
            {
                "select": "id,vehicle_id,seat_code,seat_class,status,held_by_user_id,held_by_booking_id,hold_expires_at,position_meta",
                "vehicle_id": f"eq.{vehicle_id}",
                "order": "seat_code.asc",
            },
        )

    async def confirmed_bookings(self, route_id: str, travel_date: str) -> list[dict[str, Any]]:
        return await self._get(
            "/rest/v1/bookings",
            {"select": "seat_ids", "route_id": f"eq.{route_id}", "travel_date": f"eq.{travel_date}", "status": "eq.confirmed"},
        )

    async def release_expired_holds(self) -> None:
        await self._post("/rest/v1/rpc/release_expired_seat_holds", {})

    async def release_booking_holds(self, booking_id: str) -> None:
        await self._post(
            "/rest/v1/rpc/release_booking_holds",
            {"p_booking_id": booking_id, "p_cancel": True},
        )

    async def hold_seat(self, route_id: str, seat_id: str, booking_id: str | None, travel_date: str) -> dict[str, Any]:
        rows = await self._post(
            "/rest/v1/rpc/hold_seat",
            {
                "p_route_id": route_id,
                "p_seat_id": seat_id,
                "p_booking_id": booking_id,
                "p_hold_minutes": DEFAULT_HOLD_MINUTES,
                "p_travel_date": travel_date,
            },
        )
        return rows[0] if rows else {}

    async def confirm_booking(self, booking_id: str, travel_date: str) -> dict[str, Any]:
        rows = await self._post(
            "/rest/v1/rpc/confirm_booking",
            {"p_booking_id": booking_id, "p_travel_date": travel_date},
        )
        return rows[0] if rows else {}


def seat_sort_key(seat: dict[str, Any]) -> tuple[Any, ...]:
    code = normalize_text(seat.get("seat_code"))
    match = re.match(r"([A-Za-z]+)(\d+)$", code)
    if match:
        return (match.group(1), int(match.group(2)), code)
    meta = seat.get("position_meta") or {}
    return (int(meta.get("y") or 0), int(meta.get("x") or 0), code)


def are_adjacent(left: dict[str, Any], right: dict[str, Any]) -> bool:
    left_code = normalize_text(left.get("seat_code"))
    right_code = normalize_text(right.get("seat_code"))
    left_match = re.match(r"([A-Za-z]+)(\d+)$", left_code)
    right_match = re.match(r"([A-Za-z]+)(\d+)$", right_code)
    if left_match and right_match:
        return left_match.group(1) == right_match.group(1) and int(right_match.group(2)) == int(left_match.group(2)) + 1

    left_meta = left.get("position_meta") or {}
    right_meta = right.get("position_meta") or {}
    return left_meta.get("y") == right_meta.get("y") and abs(int(right_meta.get("x") or 0) - int(left_meta.get("x") or 0)) <= 90


def choose_seats(seats: list[dict[str, Any]], booked_seat_ids: set[str], passenger_count: int, user_id: str) -> tuple[list[dict[str, Any]], str]:
    available = [
        seat for seat in seats
        if seat.get("id") not in booked_seat_ids
        and (
            seat.get("status") == "available"
            or (seat.get("status") == "held" and seat.get("held_by_user_id") == user_id)
        )
    ]
    available.sort(key=seat_sort_key)

    if len(available) < passenger_count:
        return available, "insufficient"

    if passenger_count == 1:
        return available[:1], "single"

    for index in range(0, len(available) - passenger_count + 1):
        block = available[index:index + passenger_count]
        if all(are_adjacent(block[offset], block[offset + 1]) for offset in range(len(block) - 1)):
            return block, "adjacent"

    return available[:passenger_count], "non_adjacent"


def missing_slot_prompt(slots: dict[str, Any]) -> str:
    labels = {
        "departure": "departure city",
        "destination": "destination city",
        "travel_date": "travel date (YYYY-MM-DD)",
        "passenger_count": "number of tickets",
    }
    missing = [labels[key] for key in REQUIRED_FIELDS if not slots.get(key)]
    return f"I can book that for you. Please share the {', '.join(missing)}."


def route_summary(route: dict[str, Any]) -> str:
    return (
        f"{route.get('departure')} → {route.get('destination')} "
        f"on {route.get('transport_type')} at {route.get('departure_time')}"
    )


async def build_hold_payload(tool: SupabaseTool, slots: dict[str, Any], user_id: str) -> tuple[str, dict[str, Any], dict[str, Any]]:
    routes = await tool.find_routes(slots["departure"], slots["destination"])
    if not routes:
        reply = f"I could not find a route from {slots['departure']} to {slots['destination']}. Try another city pair."
        return reply, {}, {"slots": slots}

    route = routes[0]
    invalid_departure_message = validate_departure_is_bookable(route, slots["travel_date"])
    if invalid_departure_message:
        return invalid_departure_message, {}, {"slots": clear_invalid_travel_date(slots)}

    vehicle = (route.get("vehicles") or [None])[0]
    if not vehicle:
        reply = f"I found {route_summary(route)}, but it does not have a vehicle assigned yet."
        return reply, {}, {"slots": slots}

    await tool.release_expired_holds()
    seats, bookings = await asyncio.gather(
        tool.seats_for_vehicle(vehicle["id"]),
        tool.confirmed_bookings(route["id"], slots["travel_date"]),
    )
    booked_seat_ids = {seat_id for booking in bookings for seat_id in (booking.get("seat_ids") or [])}
    selected, selection_reason = choose_seats(seats, booked_seat_ids, int(slots["passenger_count"]), user_id)

    if selection_reason == "insufficient":
        if not selected:
            reply = f"No seats are available for {route_summary(route)} on {slots['travel_date']}."
        else:
            codes = ", ".join(seat["seat_code"] for seat in selected)
            reply = (
                f"Only {len(selected)} seat is available for {route_summary(route)} on {slots['travel_date']}: "
                f"{codes}. I cannot book {slots['passenger_count']} tickets on this trip."
            )
        return reply, {}, {"slots": slots}

    booking_id = None
    hold_results = []
    for seat in selected:
        hold_result = await tool.hold_seat(route["id"], seat["id"], booking_id, slots["travel_date"])
        booking_id = hold_result.get("booking_id") or booking_id
        hold_results.append(hold_result)

    seat_codes = [seat["seat_code"] for seat in selected]
    payload = {
        "booking_id": booking_id,
        "route_id": route["id"],
        "vehicle_id": vehicle["id"],
        "travel_date": slots["travel_date"],
        "passenger_count": int(slots["passenger_count"]),
        "seat_ids": [seat["id"] for seat in selected],
        "seat_codes": seat_codes,
        "route": {
            "departure": route.get("departure"),
            "destination": route.get("destination"),
            "transport_type": route.get("transport_type"),
            "departure_time": route.get("departure_time"),
            "arrival_time": route.get("arrival_time"),
            "vehicle_code": vehicle.get("vehicle_code"),
        },
    }
    reason = "I found adjacent seats" if selection_reason == "adjacent" else "Adjacent seats were not available, so I selected the next available seats"
    if selection_reason == "single":
        reason = "I found one available seat"
    reply = (
        f"{reason}: {', '.join(seat_codes)}.\n\n"
        f"Please confirm this booking payload:\n{json.dumps(payload, indent=2)}\n\n"
        "Reply yes to create the booking, or cancel to release this hold."
    )
    state = {"slots": slots, "pending_payload": payload, "hold_results": hold_results}
    return reply, payload, state


async def handle_assistant(payload: dict[str, Any], token: str) -> dict[str, Any]:
    message = normalize_text(payload.get("message"))
    if not message:
        raise AssistantError("Message is required.")

    state = payload.get("state") if isinstance(payload.get("state"), dict) else {}
    history = payload.get("history") if isinstance(payload.get("history"), list) else []
    extracted = await extract_with_deepseek(message, history, state)

    if extracted.get("cancel"):
        return {"reply": "No problem. I will leave this booking unconfirmed.", "state": {"slots": state.get("slots", {})}}

    pending = state.get("pending_payload") or {}
    if pending and extracted.get("confirm"):
        tool = SupabaseTool(token)
        pending_route = pending.get("route") or {}
        invalid_departure_message = validate_departure_is_bookable(
            {
                "departure": pending_route.get("departure"),
                "destination": pending_route.get("destination"),
                "transport_type": pending_route.get("transport_type"),
                "departure_time": pending_route.get("departure_time"),
            },
            pending.get("travel_date"),
        )
        if invalid_departure_message:
            await tool.release_booking_holds(pending["booking_id"])
            return {
                "reply": invalid_departure_message,
                "state": {"slots": clear_invalid_travel_date(state.get("slots") or {})},
            }

        confirmation = await tool.confirm_booking(pending["booking_id"], pending["travel_date"])
        return {
            "reply": f"Booking confirmed. Ticket ID: {confirmation.get('ticket_id')}.",
            "state": {"slots": {}},
            "booking": confirmation,
        }

    slots = merge_slots(state, extracted)
    if any(not slots.get(key) for key in REQUIRED_FIELDS):
        return {
            "reply": missing_slot_prompt(slots),
            "state": {"slots": slots},
        }

    tool = SupabaseTool(token)
    user = await tool.current_user()
    if not user:
        return {"reply": "Please sign in before I create or hold seats for a booking.", "state": {"slots": slots}}

    profile = await tool.current_profile(user["id"])
    reply, booking_payload, next_state = await build_hold_payload(tool, slots, user["id"])
    return {
        "reply": reply,
        "state": next_state,
        "payload": booking_payload or None,
        "needsConfirmation": bool(booking_payload),
        "user": profile,
    }


async def app(scope, receive, send) -> None:
    if scope["type"] != "http":
        return

    path = scope.get("path", "")
    method = scope.get("method", "GET")

    if method == "OPTIONS":
        await send_json(send, {"ok": True})
        return

    if method == "GET" and path in {"/api/health", "/health"}:
        await send_json(
            send,
            {
                "status": "ok",
                "service": "assistant",
                "deepseek": deepseek_diagnostics(),
                "supabase": {
                    "url_configured": bool(SUPABASE_URL),
                    "anon_key_configured": bool(SUPABASE_ANON_KEY),
                },
            },
        )
        return

    if method != "POST" or path not in {"/api/assistant", "/assistant"}:
        await send_json(send, {"message": "Not found"}, 404)
        return

    try:
        raw_body = await read_body(receive)
        payload = json.loads(raw_body.decode("utf-8") or "{}")
        print(f"Received payload: {payload}")  # Debugging line
        token = bearer_from_headers(scope.get("headers", []))
        result = await handle_assistant(payload, token)
        await send_json(send, result)
    except AssistantError as error:
        await send_json(send, {"message": str(error)}, error.status)
    except httpx.HTTPStatusError as error:
        await send_json(send, {"message": error.response.text}, error.response.status_code)
    except Exception as error:
        await send_json(send, {"message": str(error) or "Assistant failed"}, 500)
