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
