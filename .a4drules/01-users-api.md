# users-api – Project Rules

## Project
- Mule 4 application `users-api`, Java 17, deployed to CloudHub 2.0.
- REST API, spec `users-api-spec` in OAS 3.0, base path `/api/v1`.
- Backend: DummyJSON `https://dummyjson.com`. It needs no credentials.
- JSON field names are camelCase.
- The workspace has two projects: `users-api-spec/` (the API spec) and `users-api/` (the Mule application). File paths below are relative to `users-api/`.

## Operations – exactly these five, nothing else

| Method | Path | DummyJSON call | Success response |
|---|---|---|---|
| GET | /users | GET /users | 200 `{ data: [User], page: { total, limit, skip } }` |
| GET | /users/{userId} | GET /users/{id} | 200 User |
| POST | /users | POST /users/add | 201 User |
| PATCH | /users/{userId} | PATCH /users/{id} | 200 User |
| DELETE | /users/{userId} | DELETE /users/{id} | 200 `{ id, deleted: true, deletedOn }` |

- GET /users query parameters: `limit` (integer 1–100, default 30), `skip` (integer ≥ 0, default 0), `sortBy` (one of `id`, `firstName`, `lastName`, `email`, `username`, `age`, `birthDate`), `order` (`asc` or `desc`, default `asc`). Forward only these four to DummyJSON. Never forward `limit=0`.
- `userId` is an integer, minimum 1.
- POST body `UserInput`: required `firstName`, `lastName`, `email` (format email), `age` (integer, minimum 0); optional `phone`, `username`, `gender` (`male` or `female`), `birthDate` (`YYYY-MM-DD`), `role` (`admin`, `moderator` or `user`). No other fields (`additionalProperties: false`).
- PATCH body `UserUpdate`: the same fields as `UserInput`, none required, at least one (`minProperties: 1`).
- No search, filter, login (`/auth`), carts, posts, or todos endpoints.

## User response
- Only these fields: `id`, `firstName`, `lastName`, `email`, `phone`, `username`, `age`, `gender`, `birthDate`, `role`, `image`, `address { address, city, state, postalCode, country }`, `company { name, department, title }`.
- Build it with an explicit allowlist in DataWeave, using the module `src/main/resources/modules/User.dwl` (`toUser`, `toUserPage`). Never use a denylist.
- Drop nulls, empty strings, and objects that end up empty.
- Never return `password`, `ssn`, `ein`, `bank`, `crypto`, `ip`, `macAddress`, or any field not listed above.
- `birthDate` is a string in `YYYY-MM-DD`. DummyJSON returns it without zero padding (`1996-5-30`); `toUser` normalizes it (`1996-05-30`).

## Security
- Every request needs headers `client_id` and `client_secret`. They are checked by the API Manager Client ID Enforcement policy, linked through API Autodiscovery with property `api.id`. Never write credential checks in flows.
- No plaintext secrets in XML or YAML. Secrets go only in `secure-<env>.yaml`, encrypted, loaded with Secure Configuration Properties using the key property `mule.key`. `mule.key` is supplied at runtime (a protected property on CloudHub 2.0) and is never committed.

## Errors
- Body: `{ code, message, correlationId }`, `Content-Type: application/json`.
- One global error handler in `global.xml`. No per-flow error handlers.
- `correlationId` is the `x-correlation-id` request header, or the Mule correlation id if the header is missing.
- `message` is human-readable. No stack traces, class names, or raw backend bodies.

| Status | code | When |
|---|---|---|
| 400 | BAD_REQUEST | `APIKIT:BAD_REQUEST`: invalid userId, missing or invalid field, empty PATCH body, limit out of range, invalid JSON |
| 401 | UNAUTHORIZED | Returned by the Client ID Enforcement policy, not by the app |
| 404 | USER_NOT_FOUND | `HTTP:NOT_FOUND` from DummyJSON |
| 404 | NOT_FOUND | `APIKIT:NOT_FOUND`: path does not exist |
| 405 | METHOD_NOT_ALLOWED | `APIKIT:METHOD_NOT_ALLOWED` |
| 429 | TOO_MANY_REQUESTS | Returned by the Rate Limiting policy. Documented on all operations |
| 502 | BACKEND_ERROR | `HTTP:INTERNAL_SERVER_ERROR`, `HTTP:BAD_GATEWAY`, `HTTP:SERVICE_UNAVAILABLE` (DummyJSON returned 5xx) |
| 504 | BACKEND_TIMEOUT | `HTTP:TIMEOUT`: no answer within `dummyjson.timeout` (default 10000 ms) |
| 500 | INTERNAL_ERROR | Any other error |

## DummyJSON behaviour
- POST, PATCH and DELETE are simulated. The response looks real (POST returns id 209) but nothing is stored, and a GET after a write returns the original data. This is not a bug.
- POST /users/add returns a full user template with empty strings, including empty sensitive fields. `toUser` removes them.
- DELETE returns the full user plus `isDeleted` and `deletedOn`. Map it to `{ id, deleted: true, deletedOn }`.
- Unknown id: 404 with body `{ "message": "User with id 'X' not found" }`.

## Project structure
- `src/main/mule/users-api.xml`: HTTP Listener, APIkit router, and the APIkit-generated flows. Never rename APIkit-generated flows; the router depends on their names.
- `src/main/mule/implementation-read.xml`: sub-flows `get-users`, `get-user-by-id`.
- `src/main/mule/implementation-write.xml`: sub-flows `create-user`, `update-user` (PATCH), `delete-user`.
- `src/main/mule/global.xml`: HTTP Listener config, HTTP Request config for DummyJSON, configuration properties, secure properties, Autodiscovery, global error handler.
- `src/main/resources/`: `config-local.yaml`, `config-dev.yaml`, `config-prod.yaml`, `secure-local.yaml`, `secure-dev.yaml`, `secure-prod.yaml`, selected by `mule.env`.
- `src/test/munit/`: MUnit suites. Mock DummyJSON responses with files from `src/test/resources/`.
- Sub-flow names are kebab-case. DataWeave variables and functions are camelCase.
- HTTP Request config takes host, port and timeout from properties. Never hardcode URLs or environment values in XML.

## Logging
- One INFO line in and one INFO line out per request, with method, path, status, durationMs and correlationId.
- Never log payloads, PII, or the `client_id` / `client_secret` headers.
- Unhandled errors: ERROR level, message only, no stack trace.
