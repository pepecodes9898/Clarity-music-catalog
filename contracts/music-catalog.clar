;; ================================
;; Music Catalog - Decentralized Music Database
;; ================================

;; ================================
;; Error Code Definitions
;; ================================
(define-constant ADMIN tx-sender)   ;; Sets contract administrator to transaction sender
(define-constant ERROR-SONG-NOT-FOUND (err u301))  ;; Error code when song isn't in database
(define-constant ERROR-ALREADY-EXISTS (err u302))  ;; Error code for duplicate entries
(define-constant ERROR-BAD-SONG-NAME (err u303))   ;; Error code for invalid track title
(define-constant ERROR-BAD-TIME-LENGTH (err u304)) ;; Error code for invalid track length
(define-constant ERROR-NO-PERMISSION (err u305))   ;; Error code for permission issues
(define-constant ERROR-ACCESS-FORBIDDEN (err u306)) ;; Error code for denied access
(define-constant ERROR-ADMIN-RESTRICTED (err u307)) ;; Error code for admin-only functions
(define-constant ERROR-LIMITED-OPERATION (err u308)) ;; Error code for limited operations

;; ================================
;; State Variables
;; ================================
(define-data-var track-counter uint u0)  ;; Counter for total tracks in system

;; ================================
;; Data Storage
;; ================================

;; Stores all music track information
(define-map music-catalog
    {track-id: uint} ;; Primary key: track ID
    {
        name: (string-ascii 64),          ;; Track name (max 64 chars)
        performer: (string-ascii 32),     ;; Performer name (max 32 chars)
        creator: principal,               ;; Track creator (principal address)
        length: uint,                     ;; Track length in seconds
        added-at-block: uint,             ;; Block height when track was added
        category: (string-ascii 32),      ;; Music category/style (max 32 chars)
        labels: (list 8 (string-ascii 24))  ;; Track labels (max 8 labels, each up to 24 chars)
    }
)

;; Stores access control for tracks
(define-map access-rights
    {track-id: uint, listener: principal}  ;; Composite key: track ID and user principal
    {can-access: bool}  ;; Whether user has access rights
)

;; ================================
;; Helper Functions (Private)
;; ================================

;; Verifies track existence in catalog
(define-private (track-exists (track-id uint))
    (is-some (map-get? music-catalog {track-id: track-id}))
)

;; Verifies if principal is track creator
(define-private (is-track-creator (track-id uint) (user principal))
    (match (map-get? music-catalog {track-id: track-id})
        track-info (is-eq (get creator track-info) user)
        false
    )
)

;; Gets track length in seconds
(define-private (get-track-length (track-id uint))
    (default-to u0 
        (get length 
            (map-get? music-catalog {track-id: track-id})
        )
    )
)

;; Verifies label has valid length
(define-private (valid-label (label (string-ascii 24)))
    (and 
        (> (len label) u0)
        (< (len label) u25)
    )
)

;; Validates a set of track labels
(define-private (valid-label-set (labels (list 8 (string-ascii 24))))
    (and
        (> (len labels) u0)
        (<= (len labels) u8)
        (is-eq (len (filter valid-label labels)) (len labels))
    )
)

;; ================================
;; Public Interface Functions
;; ================================

;; Adds new track to music catalog
(define-public (register-track 
        (name (string-ascii 64))
        (performer (string-ascii 32))
        (length uint)
        (category (string-ascii 32))
        (labels (list 8 (string-ascii 24)))
    )
    (let
        ((next-id (+ (var-get track-counter) u1)))

        ;; Input validation
        (asserts! (and (> (len name) u0) (< (len name) u65)) ERROR-BAD-SONG-NAME)
        (asserts! (and (> (len performer) u0) (< (len performer) u33)) ERROR-BAD-SONG-NAME)
        (asserts! (and (> length u0) (< length u10000)) ERROR-BAD-TIME-LENGTH)
        (asserts! (and (> (len category) u0) (< (len category) u33)) ERROR-BAD-SONG-NAME)
        (asserts! (valid-label-set labels) ERROR-BAD-SONG-NAME)

        ;; Store track data
        (map-insert music-catalog
            {track-id: next-id}
            {
                name: name,
                performer: performer,
                creator: tx-sender,
                length: length,
                added-at-block: block-height,
                category: category,
                labels: labels
            }
        )

        ;; Set creator access rights
        (map-insert access-rights
            {track-id: next-id, listener: tx-sender}
            {can-access: true}
        )

        ;; Update counter and return ID
        (var-set track-counter next-id)
        (ok next-id)
    )
)

;; Changes track ownership
(define-public (change-track-owner (track-id uint) (new-creator principal))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))

        ;; Validate request
        (asserts! (track-exists track-id) ERROR-SONG-NOT-FOUND)
        (asserts! (is-eq (get creator track-info) tx-sender) ERROR-NO-PERMISSION)

        ;; Update ownership
        (map-set music-catalog
            {track-id: track-id}
            (merge track-info {creator: new-creator})
        )
        (ok true)
    )
)


;; Updates track information
(define-public (modify-track-info 
        (track-id uint) 
        (updated-name (string-ascii 64)) 
        (updated-length uint) 
        (updated-category (string-ascii 32)) 
        (updated-labels (list 8 (string-ascii 24)))
    )
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))

        ;; Validate request
        (asserts! (track-exists track-id) ERROR-SONG-NOT-FOUND)
        (asserts! (is-eq (get creator track-info) tx-sender) ERROR-NO-PERMISSION)
        (asserts! (and (> (len updated-name) u0) (< (len updated-name) u65)) ERROR-BAD-SONG-NAME)
        (asserts! (and (> updated-length u0) (< updated-length u10000)) ERROR-BAD-TIME-LENGTH)
        (asserts! (and (> (len updated-category) u0) (< (len updated-category) u33)) ERROR-BAD-SONG-NAME)
        (asserts! (valid-label-set updated-labels) ERROR-BAD-SONG-NAME)

        ;; Update track info
        (map-set music-catalog
            {track-id: track-id}
            (merge track-info {
                name: updated-name,
                length: updated-length,
                category: updated-category,
                labels: updated-labels
            })
        )
        (ok true)
    )
)

;; Retrieves complete track information
(define-public (get-track-info (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok track-info)
    )
)

;; Checks if user has track access permissions
(define-public (check-listener-access (track-id uint) (listener principal))
    (let
        ((access-info (unwrap! (map-get? access-rights {track-id: track-id, listener: listener}) ERROR-SONG-NOT-FOUND)))
        (ok (get can-access access-info))
    )
)

;; Gets track creator address
(define-public (lookup-track-creator (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get creator track-info))
    )
)

;; Gets total track count in catalog
(define-public (get-catalog-size)
    (ok (var-get track-counter))
)

;; Gets track music category
(define-public (lookup-track-category (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get category track-info))
    )
)


;; Gets track labels/tags
(define-public (lookup-track-labels (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get labels track-info))
    )
)

;; Gets track performer name
(define-public (lookup-track-performer (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get performer track-info))
    )
)

;; Gets track title
(define-public (lookup-track-name (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get name track-info))
    )
)

;; Gets track length in seconds
(define-public (lookup-track-length (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get length track-info))
    )
)

;; Gets track metadata/labels
(define-public (get-track-metadata (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get labels track-info))
    )
)

;; Gets block when track was added
(define-public (lookup-track-creation-block (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get added-at-block track-info))
    )
)

;; Gets track length by creator only
(define-public (get-creator-only-track-length (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (asserts! (is-eq (get creator track-info) tx-sender) ERROR-NO-PERMISSION)
        (ok (get length track-info))
    )
)

;; Verifies listener access to track
(define-public (verify-listener-access (track-id uint) (listener principal))
    (let
        ((access-info (unwrap! (map-get? access-rights {track-id: track-id, listener: listener}) ERROR-SONG-NOT-FOUND)))
        (ok (get can-access access-info))
    )
)

;; Gets all track labels
(define-public (get-all-track-labels (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (ok (get labels track-info))
    )
)

;; Checks if track exists in catalog
(define-public (is-track-in-catalog (track-id uint))
    (let
        ((exists (is-some (map-get? music-catalog {track-id: track-id}))))
        (ok exists)
    )
)

;; Removes track from catalog
(define-public (delete-track (track-id uint))
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))

        ;; Validate request
        (asserts! (track-exists track-id) ERROR-SONG-NOT-FOUND)
        (asserts! (is-eq (get creator track-info) tx-sender) ERROR-NO-PERMISSION)

        ;; Remove track data
        (map-delete music-catalog {track-id: track-id})
        (map-delete access-rights {track-id: track-id, listener: tx-sender})
        (ok true)
    )
)

;; ================================
;; Extended Functionality
;; ================================

;; Changes track ownership with access verification
(define-public (change-owner-with-access-check 
        (track-id uint) 
        (new-creator principal)
    )
    (let
        ((track-info (unwrap! (map-get? music-catalog {track-id: track-id}) ERROR-SONG-NOT-FOUND)))
        (asserts! (is-eq (get creator track-info) tx-sender) ERROR-NO-PERMISSION)
        (asserts! (track-exists track-id) ERROR-SONG-NOT-FOUND)
        ;; Verify new owner has access rights
        (let ((access-info (unwrap! (map-get? access-rights {track-id: track-id, listener: new-creator}) ERROR-ACCESS-FORBIDDEN)))
            (asserts! (get can-access access-info) ERROR-ACCESS-FORBIDDEN)
        )
        ;; Transfer ownership
        (map-set music-catalog
            {track-id: track-id}
            (merge track-info {creator: new-creator})
        )
        (ok true)
    )
)
