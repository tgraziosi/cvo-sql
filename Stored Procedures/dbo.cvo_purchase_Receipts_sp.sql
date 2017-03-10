SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvo_purchase_Receipts_sp] (@sdate DATETIME = null, @edate DATETIME = NULL , @vendor VARCHAR(1024) = null)
AS 
BEGIN

	SET NOCOUNT ON;

-- exec cvo_purchase_receipts_sp

-- ALTER view [dbo].[adrec_vw] as

IF(OBJECT_ID('tempdb.dbo.#vendor') is not null)  drop table dbo.#vendor

--declare @Territory varchar(1000)
--select  @Territory = null

create table #vendor (vendor varchar(12), vendor_name VARCHAR(40))

if @vendor is null
begin
 insert into #vendor ( vendor, vendor_name )
  select ap.vendor_code, ap.address_name vendor_name from apmaster ap 
	WHERE EXISTS (SELECT 1 FROM dbo.purchase AS p WHERE p.vendor_no = ap.vendor_code) 
end
else
begin
 insert into #vendor ( vendor, vendor_name )
  select listitem, ap.address_name
  from dbo.f_comma_list_to_table(@vendor)
  JOIN dbo.apmaster AS ap ON ap.vendor_code = listitem
END


IF @sdate IS NULL OR @edate IS NULL
 SELECT @sdate = begindate, @edate = enddate FROM dbo.cvo_date_range_vw AS drv WHERE period = 'Last Quarter'

select 
	r.receipt_no ,
	r.po_key , 
	p.line,
	r.vendor , 
	v.vendor_name,
	r.location ,
	r.part_no , 
	p.description , 
	r.unit_measure ,
	p.qty_ordered , 
 	qty_received = r.quantity , 
	date_received = r.recv_date , 
	qc_desc=
		CASE r.qc_flag
			WHEN 'N' THEN 'No'
			WHEN 'Y' THEN 'Yes'
			WHEN 'F' THEN 'No'					-- mls 02/21/03 SCR 29078
			ELSE ''
		END, 	
	r.status,
	
	status_desc = 
		CASE r.status
			WHEN 'R' THEN 'Received'
			WHEN 'S' THEN 'Matched'
			ELSE ''
		END, 
	r.unit_cost , 
	Ext_price = ROUND(r.unit_cost * r.quantity,2),
	 
 r.part_type ,
 r.sku_no , 
 r.who_entered,
 r.voucher_no ,
 i.tolerance_cd,
 
 	-- EL - 051214 -- Air or Ocean Delivery Method
	Case when p.ship_via_method IS NULL and pa.ship_via_method IS NULL THEN 'NA'
		WHEN p.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method = 2 THEN 'Ocean'
		WHEN p.ship_via_method IS NULL and pa.ship_via_method = 0 THEN 'None'
			WHEN p.ship_via_method IS NULL and pa.ship_via_method = 1 THEN 'Air'
				WHEN p.ship_via_method IS NULL and pa.ship_via_method = 2 THEN 'Ocean'
					ELSE 'XXXXXXXX' END AS ship_via_method,

i.type_code , -- 12/8/2014 - tag -- acctg request to add

--x_receipt_no=r.receipt_no ,
--x_po_key=r.po_key , 
--x_line=p.line,
--x_qty_ordered=p.qty_ordered , 
--x_qty_received = r.quantity , 
--x_date_received = ((datediff(day, '01/01/1900', r.recv_date) + 693596)) + (datepart(hh,r.recv_date)*.01 + datepart(mi,r.recv_date)*.0001 + datepart(ss,r.recv_date)*.000001),
--x_unit_cost=r.unit_cost 
vm.defective_pct,
i.category Brand,
ia.field_2 Style,
ISNULL(cmi.special_program,'') special_program,
incl_in_defects = CASE WHEN ISNULL(cmi.special_program,'') 
	IN ('Compass','Private Label TSO','HVC','Lux Sears','Lux Pearl','JC Penny',
		'Costco','Retail- BCBG Stores','Retail- Nordstrom')
	THEN 'NO' ELSE 'YES' end


from #vendor AS v
JOIN receipts_all r ON r.vendor = v.vendor
join pur_list p (nolock) on r.po_key = p.po_key and r.part_no = p.part_no
  and p.line = case when isnull(r.po_line,0)=0 then p.line else r.po_line end	-- mls 5/9/01  SCR 6603 
left outer join inv_master i (nolock) on i.part_no = r.part_no							-- mls 2/14/01 SCR 25365
  and r.part_type = 'P' 
inner join purchase_all pa (nolock) on pa.po_key = p.po_key -- EL - 051214 -- Air or Ocean Delivery Method
LEFT OUTER JOIN dbo.cvo_Vendor_MOQ AS vm ON vm.Vendor_Code = r.vendor
LEFT OUTER JOIN inv_master_add ia ON ia.part_no = r.part_no
LEFT OUTER JOIN dbo.cvo_cmi_models AS cmi ON cmi.model_name = ia.field_2 AND cmi.brand = i.category




WHERE r.recv_date BETWEEN @sdate AND @edate

  
 END
GO
GRANT EXECUTE ON  [dbo].[cvo_purchase_Receipts_sp] TO [public]
GO
