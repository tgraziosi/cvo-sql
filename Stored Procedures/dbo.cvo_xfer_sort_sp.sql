SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_xfer_sort_sp] @from_loc VARCHAR(10), @rel_date DATETIME
AS

SET NOCOUNT ON 

-- exec cvo_xfer_sort_sp '999' , '06/27/2017'
-- select * From cvo_xfer_sort_tbl where part_no like 'et%'
SELECT * FROM xfer_list WHERE part_no LIKE 'etalbupur%'
-- truncate cvo_xfer_sort_tbl

IF (OBJECT_ID('dbo.cvo_xfer_sort_tbl')) is NULL
BEGIN

	CREATE TABLE cvo_xfer_sort_tbl
	(
		rel_date DATETIME,
		xfer_no INT,
		line_no INT,
		from_loc VARCHAR(10),
		to_loc VARCHAR(10),
		part_no VARCHAR(30),
		upc_code VARCHAR(20),
		ordered DECIMAL(20, 8),
		shipped DECIMAL(20, 8),
		carton_no INT,
		pack_qty DECIMAL(24, 8),
		qty_to_pack DECIMAL(24, 8),
		sch_ship_date DATETIME,
		status CHAR(1),
		date_scanned DATETIME,
		qty_scanned INT,
		rec_id int IDENTITY(1,1))

	CREATE INDEX cvo_xfer_pk ON dbo.cvo_xfer_sort_tbl (rec_id asc)
	
END

-- sku counts
INSERT dbo.cvo_xfer_sort_tbl
(
    rel_date,
    xfer_no,
    line_no,
    from_loc,
    to_loc,
    part_no,
    upc_code,
    ordered,
    shipped,
    carton_no,
    pack_qty,
    qty_to_pack,
    sch_ship_date,
    status,
    date_scanned,
	qty_scanned
)

SELECT ia.field_26 rel_date, 
xl.xfer_no,                   
xl.line_no,
xl.from_loc,
xl.to_loc,
xl.part_no,
i.upc_code,
xl.ordered,
xl.shipped,
c.carton_no,
c.pack_qty,
c.qty_to_pack,
x.sch_ship_date,
x.status,
CAST(NULL AS DATETIME) AS date_scanned,
cast (0 AS INTEGER) AS qty_scanned

FROM dbo.xfers AS x 
JOIN dbo.xfer_list AS xl ON xl.xfer_no = x.xfer_no
JOIN dbo.tdc_carton_detail_tx  AS c ON c.order_no = x.xfer_no AND c.line_no = xl.line_no AND c.part_no = xl.part_no AND c.order_ext = 0
JOIN inv_master i ON i.part_no = xl.part_no
JOIN inv_master_add ia ON ia.part_no = xl.part_no
WHERE 1=1
AND x.status < 's'
AND c.status = 'o'
and x.from_loc = @from_loc
AND ia.field_26 <= @rel_date
AND xl.to_loc > '200'
AND NOT EXISTS ( SELECT 1 FROM cvo_xfer_sort_tbl x WHERE x.xfer_no = xl.xfer_no AND x.part_no = xl.part_no AND x.line_no = xl.line_no)

GRANT EXECUTE ON dbo.cvo_xfer_sort_sp TO PUBLIC

/*

-- SELECT DISTINCT LEFT(part_no,6), rel_date FROM dbo.cvo_xfer_sort_tbl AS xst
SELECT COUNT(part_no), to_loc FROM dbo.cvo_xfer_sort_tbl AS xst
GROUP BY xst.to_loc

SELECT * FROM dbo.cvo_xfer_sort_tbl AS xst WHERE xst.to_loc = '530 - MUEH'
*/

GO
GRANT EXECUTE ON  [dbo].[cvo_xfer_sort_sp] TO [public]
GO
