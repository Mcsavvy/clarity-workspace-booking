;; Define constants for the contract
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-workspace (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-not-booked (err u103))
(define-constant err-unauthorized (err u104))

;; Define data structures
(define-map workspaces
    uint
    {
        capacity: uint,
        price-per-day: uint,
        is-active: bool
    }
)

(define-map bookings
    {workspace-id: uint, date: uint}
    {
        booker: principal,
        paid-amount: uint
    }
)

;; Administrative functions
(define-public (add-workspace (workspace-id uint) (capacity uint) (price-per-day uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set workspaces workspace-id {
                capacity: capacity,
                price-per-day: price-per-day,
                is-active: true
            })
            (ok true)
        )
        err-owner-only
    )
)

(define-public (deactivate-workspace (workspace-id uint))
    (if (is-eq tx-sender contract-owner)
        (match (map-get? workspaces workspace-id)
            workspace (begin
                (map-set workspaces workspace-id {
                    capacity: (get capacity workspace),
                    price-per-day: (get price-per-day workspace),
                    is-active: false
                })
                (ok true)
            )
            err-invalid-workspace
        )
        err-owner-only
    )
)

;; Booking functions
(define-public (book-workspace (workspace-id uint) (date uint))
    (let (
        (workspace (unwrap! (map-get? workspaces workspace-id) err-invalid-workspace))
        (booking-key {workspace-id: workspace-id, date: date})
    )
        (if (get is-active workspace)
            (match (map-get? bookings booking-key)
                existing-booking err-already-booked
                (begin
                    (map-set bookings booking-key {
                        booker: tx-sender,
                        paid-amount: (get price-per-day workspace)
                    })
                    (ok true)
                )
            )
            err-invalid-workspace
        )
    )
)

(define-public (cancel-booking (workspace-id uint) (date uint))
    (let (
        (booking-key {workspace-id: workspace-id, date: date})
        (booking (unwrap! (map-get? bookings booking-key) err-not-booked))
    )
        (if (is-eq tx-sender (get booker booking))
            (begin
                (map-delete bookings booking-key)
                (ok true)
            )
            err-unauthorized
        )
    )
)

;; Read-only functions
(define-read-only (get-workspace-info (workspace-id uint))
    (ok (map-get? workspaces workspace-id))
)

(define-read-only (get-booking-info (workspace-id uint) (date uint))
    (ok (map-get? bookings {workspace-id: workspace-id, date: date}))
)

(define-read-only (is-workspace-available (workspace-id uint) (date uint))
    (match (map-get? bookings {workspace-id: workspace-id, date: date})
        booking false
        true
    )
)
