%dw 2.0
// =============================================================================
// MODULE : map-carrier-status.dwl
//
// PURPOSE
//   Translates a carrier-specific status string into the canonical
//   ShipmentStatus enum defined in the OAS 3.0 spec:
//     PICKED_UP | IN_TRANSIT | OUT_FOR_DELIVERY | DELIVERED |
//     EXCEPTION | RETURNED | UNKNOWN
//
// USAGE
//   Import this module wherever a raw carrier status needs to be normalised:
//     %dw 2.0
//     import mapCarrierStatus from dw::map-carrier-status
//     output application/java
//     ---
//     mapCarrierStatus("PU", "FEDEX")   // returns "PICKED_UP"
//
// TODO (implement when adding business logic)
//   Populate each carrier match block with the actual status codes returned
//   by the carrier APIs. Reference:
//     FedEx : https://developer.fedex.com/api/en-us/catalog/tracking/v1/docs.html
//             (DerivedStatusCode values: PU, OC, IT, OD, DL, DE, RS, ...)
//     UPS   : https://developer.ups.com/api/reference/tracking/
//             (Activity.Status.Type: P, I, O, D, X, RS, ...)
//     DHL   : https://developer.dhl.com/api-reference/shipment-tracking
//             (events.status: pre-transit, transit, delivered, failure, ...)
//     USPS  : https://www.usps.com/business/web-tools-apis/track-and-confirm-api.htm
//             (TrackSummary.EventCode: A, B, ..., various status descriptions)
// =============================================================================

// ---------------------------------------------------------------------------
// Placeholder stub — replace the match/case blocks with real status mappings.
// ---------------------------------------------------------------------------

fun mapCarrierStatus(rawStatus: String, carrier: String): String =
    carrier match {
        case "FEDEX" -> mapFedExStatus(rawStatus)
        case "UPS"   -> mapUpsStatus(rawStatus)
        case "DHL"   -> mapDhlStatus(rawStatus)
        case "USPS"  -> mapUspsStatus(rawStatus)
        else         -> "UNKNOWN"
    }

// FedEx status code mapping
// TODO: Expand with full DerivedStatusCode values from FedEx API docs
fun mapFedExStatus(rawStatus: String): String =
    rawStatus match {
        case "PU" -> "PICKED_UP"
        case "IT" -> "IN_TRANSIT"
        case "OD" -> "OUT_FOR_DELIVERY"
        case "DL" -> "DELIVERED"
        case "DE" -> "EXCEPTION"
        case "RS" -> "RETURNED"
        else      -> "UNKNOWN"
    }

// UPS status code mapping
// TODO: Expand with full Activity.Status.Type values from UPS API docs
fun mapUpsStatus(rawStatus: String): String =
    rawStatus match {
        case "P" -> "PICKED_UP"
        case "I" -> "IN_TRANSIT"
        case "O" -> "OUT_FOR_DELIVERY"
        case "D" -> "DELIVERED"
        case "X" -> "EXCEPTION"
        else     -> "UNKNOWN"
    }

// DHL status code mapping
// TODO: Expand with full events.status values from DHL API docs
fun mapDhlStatus(rawStatus: String): String =
    rawStatus match {
        case "pre-transit" -> "PICKED_UP"
        case "transit"     -> "IN_TRANSIT"
        case "delivered"   -> "DELIVERED"
        case "failure"     -> "EXCEPTION"
        else               -> "UNKNOWN"
    }

// USPS status code mapping
// TODO: Expand with full EventCode values and description strings from USPS API docs
fun mapUspsStatus(rawStatus: String): String =
    rawStatus match {
        case "A"   -> "PICKED_UP"
        case "I"   -> "IN_TRANSIT"
        case "OF"  -> "OUT_FOR_DELIVERY"
        case "D"   -> "DELIVERED"
        case "X"   -> "EXCEPTION"
        else       -> "UNKNOWN"
    }

---
// Required body expression for standalone .dwl file validation.
// Has no runtime effect when this file is used as an imported module.
mapCarrierStatus("UNKNOWN", "FEDEX")