;; Define constants for the contract
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-workspace (err u101))
(define-constant err-already-booked (err u102))
(define-constant err-not-booked (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-invalid-payment (err u105))
(define-constant err-invalid-date (err u106))

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

;; Helper function for date validation
(define-private (is-valid-date (date uint))
    (let ((current-date (get-current-date)))
        (and (>= date current-date)
             (<= date (+ current-date u365)))
    )
)

;; Booking functions
(define-public (book-workspace (workspace-id uint) (date uint))
    (let (
        (workspace (unwrap! (map-get? workspaces workspace-id) err-invalid-workspace))
        (booking-key {workspace-id: workspace-id, date: date})
    )
        (if (not (is-valid-date date))
            err-invalid-date
            (if (get is-active workspace)
                (match (map-get? bookings booking-key)
                    existing-booking err-already-booked
                    (let ((price (get price-per-day workspace)))
                        (if (is-eq (stx-transfer? price tx-sender contract-owner))
                            (begin
                                (map-set bookings booking-key {
                                    booker: tx-sender,
                                    paid-amount: price
                                })
                                (ok true)
                            )
                            err-invalid-payment
                        ))
                )
                err-invalid-workspace
            ))
    )
)

;; Other functions remain unchanged...
