SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[cvo_dc_dash_recv_sp] @recalc_usage INT = 0, @det INT = 0, @days_out INT = 5

AS

-- exec cvo_dc_dash_recv_sp 0, 1, 5

-- SELECT top 100 * FROM ##cvo_usage 
-- SELECT * FROM cvo_dc_dash_recv_tbl


SET NOCOUNT ON

DECLARE @asofdate DATETIME, @lastusgupdate DATETIME
SELECT @asofdate = GETDATE()


IF ( OBJECT_ID('dbo.cvo_dc_dash_recv_tbl') IS NULL )
begin
CREATE TABLE dbo.cvo_dc_dash_recv_tbl
(
    due_days INT,
    inhouse_date DATETIME,
    vendor_no VARCHAR(12),
    po_key INT,
    category VARCHAR(8),
    line INT,
    location VARCHAR(10),
    part_no VARCHAR(30),
    description VARCHAR(255),
    item_type VARCHAR(13),
    unit_measure VARCHAR(2),
    weight_ea DECIMAL(20, 8),
    qty_ordered DECIMAL(20, 8),
    qty_received DECIMAL(20, 8),
    qty_open DECIMAL(21, 8),
    Last_Receipt INT,
    Last_receipt_date DATETIME,
    recv_days INT,
    Pk_lst VARCHAR(5),
    status CHAR(1),
    status_desc VARCHAR(6),
    e4_wu INT,
    e12_wu INT,
    qty_avl DECIMAL(38, 8),
    open_ord DECIMAL(38, 8),
    Info_tag VARCHAR(11),
    Method VARCHAR(5),
    note VARCHAR(255),
    type_code VARCHAR(10)
);
    GRANT ALL ON dbo.cvo_dc_dash_recv_tbl TO PUBLIC;
    CREATE INDEX idx_dash_recv ON dbo.cvo_dc_dash_recv_tbl (po_key);

END;


IF (OBJECT_ID('tempdb.dbo.##cvo_usage') is NOT NULL) 
begin
    SELECT DISTINCT @lastusgupdate  = asofdate FROM ##cvo_usage
    IF DATEDIFF(DAY,@lastusgupdate,@asofdate) > 1  SELECT @recalc_usage = 1
end

IF @recalc_usage = 1 OR (OBJECT_ID('tempdb.dbo.##cvo_usage') is NULL)
BEGIN

	IF(OBJECT_ID('tempdb.dbo.##cvo_usage') is not null)  drop table ##cvo_usage
	SELECT fccwu.location ,
		   fccwu.part_no ,
		   fccwu.usg_option ,
		   fccwu.asofdate ,
		   fccwu.e4_wu ,
		   fccwu.e12_wu ,
		   fccwu.e26_wu ,
		   fccwu.e52_wu ,
		   ISNULL(iav.qty_avl,0) qty_avl,
		   ISNULL(iav.sof,0)+ISNULL(iav.Allocated,0) open_ord
	INTO ##cvo_usage
	FROM dbo.f_cvo_calc_weekly_usage_coll('o',null) AS fccwu
	LEFT JOIN dbo.cvo_item_avail_vw AS iav ON iav.location = fccwu.location AND iav.part_no = fccwu.part_no
	CREATE INDEX idx_cvo_usage ON ##cvo_usage (location, PART_no)
	
END


IF @det = -1
begin
select 
	DATEDIFF(d, @asofdate, ISNULL(r.inhouse_date, r.confirm_date)) due_days,
	isnull(r.inhouse_date, r.confirm_date) inhouse_date,
--	ISNULL(r.departure_date, r.confirm_date) departure_date,
    	Case when p.ship_via_method IS NULL and pa.ship_via_method IS NULL THEN 'Ocean'
				WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IN (0,2) THEN 'Ocean' -- none or ocean
                ELSE 'Ocean'
                END AS ship_via,
	aa.address_name vendor_name,
	b.brands,
	COUNT(p.line) num_lines ,
	MAX(CASE  WHEN ia.field_26 > @asofdate THEN 'New Release' 
		  WHEN 	isnull(drp.qty_avl,0) < 0 AND isnull(drp.open_ord,0) > 0 THEN 'Backorders'
		  ELSE '' END 
		) AS Info_tag,
	qty_open = case when SUM(qty_ordered-qty_received) < 0 then 0
					else SUM(qty_ordered-qty_received)
				end
from pur_list p (nolock) 
inner join purchase_all pa (nolock)
on pa.po_key = p.po_key
INNER JOIN dbo.apmaster_all AS aa (NOLOCK) ON aa.vendor_code = pa.vendor_no
left join releases r (nolock)
on p.po_key = r.po_key and p.line = r.po_line
left join inv_master_add ia (nolock) on p.part_no = ia.part_no
left join ##cvo_usage AS drp (nolock) 
on p.part_no = drp.part_no and p.location = drp.location
LEFT OUTER JOIN
(SELECT DISTINCT ppp.po_key, brands = STUFF (( SELECT DISTINCT ';' + i.category
												 FROM pur_list pp  (NOLOCK)
												 JOIN inv_master i (NOLOCK) ON pp.part_no = i.part_no
												 WHERE pp.status = 'o' AND pp.void <> 'v'
												 AND pp.po_key = ppp.po_key
									 FOR XML PATH('') ),1,1, '' )
			 FROM dbo.purchase AS ppp (NOLOCK)
			 WHERE ppp.status = 'o' AND ppp.void <> 'v' ) b ON b.po_key = pa.po_key
		  
where p.po_key = p.po_no and pa.po_no = pa.po_key
and r.po_key = r.po_no
AND p.status = 'o' AND p.void <> 'v'
AND DATEDIFF(d, @asofdate, isnull(r.inhouse_date, r.confirm_date)) BETWEEN -@days_out AND @days_out
GROUP BY DATEDIFF(d, @asofdate, ISNULL(r.inhouse_date, r.confirm_date)),
         ISNULL(r.inhouse_date, r.confirm_date),
         CASE
         WHEN p.ship_via_method IS NULL
         AND pa.ship_via_method IS NULL THEN
         'Ocean'
         WHEN p.ship_via_method = 1 THEN
         'Air'
         WHEN p.ship_via_method IN ( 0, 2 ) THEN
         'Ocean' -- none or ocean
         ELSE
         'Ocean'
         END,
         aa.address_name,
         b.brands


END

IF @det = 0
begin
select 
	DATEDIFF(d, @asofdate, ISNULL(r.inhouse_date, r.confirm_date)) due_days,
	isnull(r.inhouse_date, r.confirm_date) inhouse_date,
--	ISNULL(r.departure_date, r.confirm_date) departure_date,
	aa.address_name vendor_name,
	pa.po_key ,
	pa.user_category category,
	p.location ,
	b.brands,
	COUNT(DISTINCT p.part_no) num_skus ,
	MAX(CASE  WHEN ia.field_26 > @asofdate THEN 'New Release' 
		  WHEN 	isnull(drp.qty_avl,0) < 0 AND isnull(drp.open_ord,0) > 0 THEN 'Backorders'
		  ELSE '' END 
		) AS Info_tag,
	qty_open = case when SUM(qty_ordered-qty_received) < 0 then 0
					else SUM(qty_ordered-qty_received)
				end,
	(SELECT MAX(recv_date) FROM dbo.receipts_all AS ra2 (NOLOCK) WHERE ra2.po_key = pa.po_key) Last_receipt_date,
	case when isnull(p.plrecd,0) = 1 then 'Yes-L'
		 when isnull(pa.expedite_flag,0) = 1 then 'Yes-H' 
		 else 'No' end as Pk_lst
from pur_list p (nolock) 
inner join purchase_all pa (nolock)
on pa.po_key = p.po_key
INNER JOIN dbo.apmaster_all AS aa (NOLOCK) ON aa.vendor_code = pa.vendor_no
left join releases r (nolock)
on p.po_key = r.po_key and p.line = r.po_line
left join inv_master_add ia (nolock) on p.part_no = ia.part_no
left join ##cvo_usage AS drp (nolock) 
on p.part_no = drp.part_no and p.location = drp.location
LEFT OUTER JOIN
(SELECT DISTINCT ppp.po_key, brands = STUFF (( SELECT DISTINCT ';' + i.category
												 FROM pur_list pp  (NOLOCK)
												 JOIN inv_master i (NOLOCK) ON pp.part_no = i.part_no
												 WHERE pp.status = 'o' AND pp.void <> 'v'
												 AND pp.po_key = ppp.po_key
									 FOR XML PATH('') ),1,1, '' )
			 FROM dbo.purchase AS ppp (NOLOCK)
			 WHERE ppp.status = 'o' AND ppp.void <> 'v' ) b ON b.po_key = pa.po_key
		  
where p.po_key = p.po_no and pa.po_no = pa.po_key
and r.po_key = r.po_no
AND p.status = 'o' AND p.void <> 'v'
AND DATEDIFF(d, @asofdate, isnull(r.inhouse_date, r.confirm_date)) BETWEEN -@days_out AND @days_out
GROUP BY DATEDIFF(d, @asofdate, ISNULL(r.inhouse_date, r.confirm_date)) ,
         ISNULL(r.inhouse_date, r.confirm_date) ,
         CASE WHEN ISNULL(p.plrecd, 0) = 1 THEN 'Yes-L'
         WHEN ISNULL(pa.expedite_flag, 0) = 1 THEN 'Yes-H'
         ELSE 'No'
         END ,
         aa.address_name ,
         pa.po_key ,
         pa.user_category ,
         p.location ,
		 b.brands
--ORDER BY 	isnull(r.inhouse_date, r.confirm_date), p.po_key
END


IF @det = 1
BEGIN
TRUNCATE TABLE dbo.cvo_dc_dash_recv_tbl;

INSERT dbo.cvo_dc_dash_recv_tbl
(
    due_days,
    inhouse_date,
    vendor_no,
    po_key,
    category,
    line,
    location,
    part_no,
    description,
    item_type,
    unit_measure,
    weight_ea,
    qty_ordered,
    qty_received,
    qty_open,
    Last_Receipt,
    Last_receipt_date,
    recv_days,
    Pk_lst,
    status,
    status_desc,
    e4_wu,
    e12_wu,
    qty_avl,
    open_ord,
    Info_tag,
    Method,
    note,
    type_code
)
SELECT 
	DATEDIFF(d, @asofdate, ISNULL(r.inhouse_date, r.confirm_date)) due_days,
	isnull(r.inhouse_date, r.confirm_date) inhouse_date,
--	ISNULL(r.departure_date, r.confirm_date) departure_date,
	pa.vendor_no,
	pa.po_key ,
	pa.user_category category,
	--pa.date_of_order,
	p.line ,
	p.location ,
	p.part_no ,
	i.description,

	item_type=
		CASE type
			WHEN 'P' THEN 'Purchase Item'
			WHEN 'M' THEN 'Miscellaneous'
			ELSE ''
		END, 
	unit_measure,
	i.weight_ea,
	qty_ordered ,
	qty_received ,
	qty_open = case when qty_ordered-qty_received < 0 then 0
					else qty_ordered-qty_received
				end,
	-- 2/24/15 - 
	ra.max_receipt Last_Receipt,
	ra.max_recv_date Last_receipt_date,
	DATEDIFF(d,isnull(r.inhouse_date, r.confirm_date),ISNULL(ra.max_recv_date,isnull(r.inhouse_date, r.confirm_date))) recv_days,
	case when isnull(p.plrecd,0) = 1 then 'Yes-L'
		 when isnull(pa.expedite_flag,0) = 1 then 'Yes-H' 
		 else 'No' end as Pk_lst,
	p.status ,  
	status_desc =   
    CASE p.status + p.void    
		WHEN 'ON' THEN 'Open'  
		WHEN 'OO' THEN 'Open'
		WHEN 'HN' THEN 'Hold'  
		WHEN 'CV' THEN 'Void'  
		WHEN 'OV' THEN 'Void'
		WHEN 'CO' THEN 'Closed'
		WHEN 'CN' THEN 'Closed'  
	--   WHEN 'V' THEN 'Void'  pre-SCR 28228 KJC Jan 24 2002  
		ELSE ''  
    END,   
	-- tag - 031813 -- add drp info
	ISNULL(drp.e4_wu,0)  e4_wu,
	ISNULL(drp.e12_wu,0)  e12_wu,
	isnull(drp.qty_avl,0)  qty_avl,
	isnull(drp.open_ord,0)  open_ord,
	CASE  WHEN ia.field_26 > @asofdate THEN 'New Release' 
		  WHEN 	isnull(drp.qty_avl,0) < 0 AND isnull(drp.open_ord,0) > 0 THEN 'Backorders'
		  ELSE '' END AS Info_tag,
	-- EL - 050914 -- Air or Ocean Delivery Method
	Case when p.ship_via_method IS NULL and pa.ship_via_method IS NULL THEN 'Ocean'
			WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IN (0,2) THEN 'Ocean'
		WHEN p.ship_via_method IS NULL and pa.ship_via_method = 0 THEN 'Ocean'
			WHEN p.ship_via_method IS NULL and pa.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IS NULL and pa.ship_via_method = 2 THEN 'Ocean'
					ELSE 'Ocean' END AS Method,
	
	isnull(dbo.cvo_fn_rem_crlf(pa.note),'') as note
	--isnull(ltrim(rtrim(left(pa.note,60))),'') note
	, i.type_code

from pur_list p (nolock) 
inner join purchase_all pa (nolock)
on pa.po_key = p.po_key
left join releases r (nolock)
on p.po_key = r.po_key and p.line = r.po_line
left join inv_master_add ia (nolock) on p.part_no = ia.part_no
left join inv_master i (nolock) on i.part_no = p.part_no
-- tag - 031813
left join ##cvo_usage AS drp (nolock) 
on p.part_no = drp.part_no and p.location = drp.location
LEFT JOIN
(SELECT po_key, po_line, MAX(rr.receipt_no) max_receipt, MAX(rr.recv_date) max_recv_date
	FROM  dbo.receipts_all AS rr (NOLOCK)
	GROUP BY rr.po_key ,
             rr.po_line
	) ra ON ra.po_key = p.po_key AND ra.po_line = r.po_line

WHERE p.po_key = p.po_no and pa.po_no = pa.po_key
and r.po_key = r.po_no

AND ((p.status = 'o' AND p.void <> 'v') OR (ra.max_recv_date IS NOT NULL AND ra.max_recv_date >= DATEADD(dd, DATEDIFF(dd,0,@asofdate), 0)))

AND (DATEDIFF(d, @asofdate, isnull(r.inhouse_date, r.confirm_date)) BETWEEN -@days_out AND @days_out OR  (ra.max_recv_date IS NOT NULL AND ra.max_recv_date >= DATEADD(dd, DATEDIFF(dd,0,@asofdate), 0)))
--ORDER BY 	isnull(r.inhouse_date, r.confirm_date), i.vendor, p.po_key
END











GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_recv_sp] TO [public]
GO
