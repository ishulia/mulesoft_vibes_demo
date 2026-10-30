%dw 2.0

/**
 * Returns true for any value that should be kept in the output:
 * non-null and non-empty string. Numbers (including 0), booleans,
 * non-empty strings, objects, and arrays all pass.
 * Only null and "" are rejected.
 */
fun isPresent(v: Any) =
  v != null and v != ""

/**
 * Builds the address sub-object from the DummyJSON address.
 * Only the five allowed fields are included; stateCode, coordinates,
 * and any other fields are silently ignored.
 * Returns null when the resulting object would be empty.
 */
fun toAddress(a) =
  if (a == null) null
  else do {
    var result = {
      address:    a.address,
      city:       a.city,
      state:      a.state,
      postalCode: a.postalCode,
      country:    a.country
    } filterObject ((v) -> isPresent(v))
    ---
    if (isEmpty(result)) null else result
  }

/**
 * Builds the company sub-object from the DummyJSON company.
 * Only the three allowed fields are included; the nested address
 * and any other fields are silently ignored.
 * Returns null when the resulting object would be empty.
 */
fun toCompany(c) =
  if (c == null) null
  else do {
    var result = {
      name:       c.name,
      department: c.department,
      title:      c.title
    } filterObject ((v) -> isPresent(v))
    ---
    if (isEmpty(result)) null else result
  }

/**
 * Normalises DummyJSON's un-padded birth date string to ISO padded form.
 *   "1996-5-30"  -> "1996-05-30"
 *   "1982-11-6"  -> "1982-11-06"
 *   "1990-11-03" -> "1990-11-03"  (already padded, still works)
 * Returns null when the value is null or empty (e.g. POST add template).
 */
fun normalizeBirthDate(d) =
  if (d == null or d == "") null
  else (d as Date {format: "yyyy-M-d"}) as String {format: "yyyy-MM-dd"}

/**
 * Maps a raw DummyJSON user object to the public User shape.
 *
 * Explicit allow-list: only the 13 declared fields are ever emitted.
 * Blocked fields (password, ssn, ein, bank, crypto, ip, macAddress,
 * maidenName, bloodGroup, height, weight, eyeColor, hair, university,
 * userAgent, isDeleted, deletedOn, etc.) are never referenced.
 * Nulls and empty strings are dropped via conditional field syntax.
 * address and company are each filtered and dropped if they end up empty.
 */
fun toUser(u) = do {
  var addr = toAddress(u.address)
  var comp = toCompany(u.company)
  var bd   = normalizeBirthDate(u.birthDate)
  ---
  {
    (id:        u.id)         if (u.id        != null),
    (firstName: u.firstName)  if isPresent(u.firstName),
    (lastName:  u.lastName)   if isPresent(u.lastName),
    (email:     u.email)      if isPresent(u.email),
    (phone:     u.phone)      if isPresent(u.phone),
    (username:  u.username)   if isPresent(u.username),
    (age:       u.age)        if (u.age       != null),
    (gender:    u.gender)     if isPresent(u.gender),
    (birthDate: bd)           if (bd          != null),
    (role:      u.role)       if isPresent(u.role),
    (image:     u.image)      if isPresent(u.image),
    (address:   addr)         if (addr        != null),
    (company:   comp)         if (comp        != null)
  }
}

/**
 * Maps the DummyJSON paginated list response to the API page shape.
 *
 *   IN:  { users: [...], total: 208, skip: 0, limit: 30 }
 *   OUT: { data: [...],  page: { total: 208, limit: 30, skip: 0 } }
 *
 * Each user in the array is passed through toUser.
 */
fun toUserPage(body) = {
  data: body.users map (u) -> toUser(u),
  page: {
    total: body.total,
    limit: body.limit,
    skip:  body.skip
  }
}

---
{}
