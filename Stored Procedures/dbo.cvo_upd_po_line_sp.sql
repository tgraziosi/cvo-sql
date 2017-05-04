SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_upd_po_line_sp]
    @po INT,
    @po_line INT,
    @part_no VARCHAR(40),
    @ship_via_method INT = NULL,
    @plrecd INT = NULL,
    @confirm_date DATETIME = NULL,
    @confirmed CHAR(1) = NULL,
    @departure_date DATETIME = NULL,
    @debug INT = 1

-- exec cvo_upd_po_line_sp 61201, 1, 'bcnolabla5117', null, null, null ,null, null, 1

AS
BEGIN

    SELECT
        p.vendor_no,
        p.user_category,
        p.po_key,
        pl.line,
        pl.part_no,
        pl.status,
        pl.void,
        pl.ship_via_method,
        pl.over_ride,
        pl.plrecd,
        r.status,
        r.confirm_date,
        r.confirmed,
        r.departure_date,
        r.inhouse_date,
        r.over_ride,
        r.quantity - r.received open_qty
    FROM
        purchase_all p
        JOIN pur_list pl
            ON pl.po_key = p.po_key
        LEFT OUTER JOIN releases r
            ON r.po_key = pl.po_key
               AND r.part_no = pl.part_no
               AND r.po_line = pl.line
    WHERE
        pl.status <> 'c'
        AND p.po_key = @po
        AND pl.line = @po_line
        AND pl.part_no = @part_no
    ;

    IF @debug = 1
    BEGIN
        SELECT
            pl.ship_via_method old_ship_via_method,
            ISNULL(@ship_via_method, pl.ship_via_method) new_ship_via_method,
            pl.plrecd old_plrecd,
            ISNULL(@plrecd, pl.plrecd) new_plrecd,
            r.confirm_date old_confirm_date,
            ISNULL(@confirm_date, r.confirm_date) new_confirm_date,
            r.confirmed old_confirmed,
            ISNULL(@confirmed, r.confirmed) new_confirmed,
            r.departure_date old_departure_date,
            ISNULL(@departure_date, r.departure_date) new_departure_date
        FROM
            pur_list pl
            JOIN releases r
                ON r.part_no = pl.part_no
                   AND r.po_key = pl.po_key
                   AND r.po_line = pl.line
        WHERE
            pl.po_key = @po
            AND pl.line = @po_line
            AND pl.part_no = @part_no
            AND
            (
                pl.ship_via_method <> ISNULL(@ship_via_method, pl.ship_via_method)
                OR pl.plrecd <> ISNULL(@plrecd, pl.plrecd)
                OR r.confirm_date <> ISNULL(@confirm_date, r.confirm_date)
                OR r.confirmed <> ISNULL(@confirmed, r.confirmed)
                OR r.departure_date <> ISNULL(@departure_date, r.departure_date)
            )
        ;
    END
    ;
    ELSE
    BEGIN
        UPDATE
            pl
        SET
            pl.ship_via_method = ISNULL(@ship_via_method, pl.ship_via_method),
            pl.plrecd = ISNULL(@plrecd, pl.plrecd)
        FROM
            pur_list pl
            JOIN releases r
                ON r.part_no = pl.part_no
                   AND r.po_key = pl.po_key
                   AND r.po_line = pl.line
        WHERE
            pl.po_key = @po
            AND pl.line = @po_line
            AND pl.part_no = @part_no
            AND
            (
                pl.ship_via_method <> ISNULL(@ship_via_method, pl.ship_via_method)
                OR pl.plrecd <> ISNULL(@plrecd, pl.plrecd)
            )
        ;

        UPDATE
            r
        SET
            r.confirm_date = ISNULL(@confirm_date, r.confirm_date),
            r.confirmed = ISNULL(@confirmed, r.confirmed),
            r.departure_date = ISNULL(@departure_date, r.departure_date)
        FROM
            pur_list pl
            JOIN releases r
                ON r.part_no = pl.part_no
                   AND r.po_key = pl.po_key
                   AND r.po_line = pl.line
        WHERE
            pl.po_key = @po
            AND pl.line = @po_line
            AND pl.part_no = @part_no
            AND
            (
                r.confirm_date <> ISNULL(@confirm_date, r.confirm_date)
                OR r.confirmed <> ISNULL(@confirmed, r.confirmed)
                OR r.departure_date <> ISNULL(@departure_date, r.departure_date)
            )
        ;

    END
    ;

END
;
GO
