SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[imPurVal_e7_sp] (
	@p_batchno  		int = 0,
	@p_start_rec		int = 0,
	@p_end_rec 		int = 0,
	@p_record_type		int = 0x00000FFF,
	@p_debug_level 		int = 0,
	@default_part_no	VARCHAR(30) = 'UPGRADE'
) AS

declare @w_cc			varchar(8)
declare @w_dmsg			varchar(255)
declare @w_highest_po_no	int
DECLARE @prev_po_key		INT
DECLARE	@po_key			INT
DECLARE @record_id_num		INT
DECLARE @cntr			INT
DECLARE @ext			CHAR(2)
DECLARE @record_type		INT
DECLARE	@result			INT
DECLARE	@home_currency		VARCHAR(8)
DECLARE	@oper_currency		VARCHAR(8)

SET NOCOUNT ON

SELECT	@w_cc = company_code, 
	@home_currency = home_currency, 
	@oper_currency = oper_currency
  FROM	glco	


if @p_debug_level > 0
begin
	set NOCOUNT OFF
	select @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
	select @w_dmsg = 'Company=' + @w_cc
	print @w_dmsg
end


create table #t99 (
	record_id_num		int
	constraint t1_pur_key 	unique nonclustered (record_id_num)
)

/*
** If the Release record types are being validated then also validate the line
** records that they are generated from
*/
SELECT @record_type = @p_record_type
IF @p_record_type & 0x00000100 > 0
BEGIN
	SELECT @record_type = @p_record_type | 0x00000010
END


IF @p_batchno > 0
BEGIN
	INSERT INTO #t99
	  SELECT record_id_num
	    FROM impur_vw
	   WHERE company_code = @w_cc
	     AND process_status = 0
	     AND batch_no = @p_batchno
END
ELSE
BEGIN
	IF @p_end_rec > 0
		INSERT INTO #t99
		  SELECT record_id_num
		    FROM impur_vw
		   WHERE company_code = @w_cc
		     AND process_status = 0
		     AND record_id_num >= @p_start_rec
		     AND record_id_num <= @p_end_rec
	ELSE
		INSERT INTO #t99
		  SELECT record_id_num
		    FROM impur_vw
		   WHERE company_code = @w_cc
		     AND process_status = 0
		     AND record_id_num >= @p_start_rec
END

if @p_debug_level > 0
begin
	select @w_cc as company_code, @p_batchno as Batch, @p_start_rec as Start_Record, @p_end_rec as End_Record
	select * from #t99
end

if @p_debug_level >= 6
begin
	select * from #t99
	print 'Exiting on debug request'
	return
end

declare	@RECTYPE_PUR_HDR	int
declare @RECTYPE_PUR_LINE	int
declare @RECTYPE_PUR_REL	int

select 	@RECTYPE_PUR_HDR	= 0x01
select	@RECTYPE_PUR_LINE	= 0x10
select	@RECTYPE_PUR_REL	= 0x100

declare @ERR_PUR_PONO		int
declare @ERR_PUR_STATUS		int
declare @ERR_PUR_PRINTFLAG	int
declare @ERR_PUR_VENDORCODE	int
declare @ERR_PUR_SHIP_TO_NO	int
declare @ERR_PUR_SHIP_NAME	int
declare @ERR_PUR_SHIP_VIA	int
declare @ERR_PUR_FOB		int
declare	@ERR_PUR_TAXCODE	int
declare	@ERR_PUR_LOC		int
declare @ERR_PUR_BUYER		int
declare @ERR_PUR_TERMS		int
declare @ERR_PUR_POSTN_CODE	int
declare @ERR_PUR_HOLDCODE	int
declare @ERR_PUR_CURR		int
declare @ERR_PUR_NOLIN		int
declare @ERR_PUR_INVLD_LIN	int
declare @ERR_PUR_DUP		int
declare @ERR_PUR_HDR_1		int

select 	@ERR_PUR_PONO		= 0x00000001
select 	@ERR_PUR_STATUS		= 0x00000002
select 	@ERR_PUR_PRINTFLAG	= 0x00000004
select 	@ERR_PUR_VENDORCODE	= 0x00000008
select 	@ERR_PUR_SHIP_TO_NO	= 0x00000010
select 	@ERR_PUR_SHIP_NAME	= 0x00000020
select 	@ERR_PUR_SHIP_VIA	= 0x00000040
select 	@ERR_PUR_FOB		= 0x00000080
select 	@ERR_PUR_TAXCODE	= 0x00000100
select 	@ERR_PUR_LOC		= 0x00000200
select 	@ERR_PUR_BUYER		= 0x00000400
select 	@ERR_PUR_TERMS		= 0x00000800
select 	@ERR_PUR_POSTN_CODE	= 0x00001000
select 	@ERR_PUR_HOLDCODE	= 0x00002000
select 	@ERR_PUR_CURR		= 0x00004000
select 	@ERR_PUR_NOLIN		= 0x00008000
select 	@ERR_PUR_INVLD_LIN	= 0x00080000	-- not in @ERR_PUR_HDR_1
select 	@ERR_PUR_DUP		= 0x08000000


declare @ERR_PUR_MC		int
declare @ERR_PUR_HDR_2		int

select 	@ERR_PUR_MC		= 0x00000002

select 	@ERR_PUR_HDR_1 		= @ERR_PUR_PONO + @ERR_PUR_STATUS + @ERR_PUR_PRINTFLAG + @ERR_PUR_VENDORCODE +
				  @ERR_PUR_SHIP_TO_NO + @ERR_PUR_SHIP_VIA +
				  @ERR_PUR_FOB + @ERR_PUR_TAXCODE + @ERR_PUR_BUYER + @ERR_PUR_TERMS +
				  @ERR_PUR_HOLDCODE + @ERR_PUR_CURR + @ERR_PUR_NOLIN +
				  @ERR_PUR_LOC + @ERR_PUR_POSTN_CODE  + @ERR_PUR_DUP
--+ @ERR_PUR_SHIP_NAME
select  @ERR_PUR_HDR_2 		= 0x00000000


declare	@ERR_PUR_L_LINENO	int
declare @ERR_PUR_L_ORDNO	int
declare @ERR_PUR_L_PARTNO	int
declare @ERR_PUR_L_LOCATION	int
declare @ERR_PUR_L_PROJCODE	int
declare @ERR_PUR_L_PARTTYPE	int
declare @ERR_PUR_L_ACCTCODE	int
declare @ERR_PUR_L_REFCODE	int
declare @ERR_PUR_L_UNITMEASURE	int

declare @ERR_PUR_L_PARTDUP	int

declare @ERR_PUR_LINE_1		int
declare @ERR_PUR_LINE_2		int

select 	@ERR_PUR_L_LINENO	= 0x00010000
select 	@ERR_PUR_L_ORDNO	= 0x00100000
select 	@ERR_PUR_L_PARTNO	= 0x00200000
select 	@ERR_PUR_L_LOCATION	= 0x00400000
select 	@ERR_PUR_L_UNITMEASURE	= 0x01000000
select 	@ERR_PUR_L_PARTTYPE	= 0x02000000
select	@ERR_PUR_L_ACCTCODE	= 0x04000000
select 	@ERR_PUR_L_PROJCODE	= 0x10000000
select 	@ERR_PUR_L_REFCODE	= 0x20000000

select  @ERR_PUR_L_PARTDUP	= 0x00000008

select 	@ERR_PUR_LINE_1 	= @ERR_PUR_L_ORDNO + @ERR_PUR_L_PARTNO + @ERR_PUR_L_LOCATION +
				@ERR_PUR_L_UNITMEASURE + @ERR_PUR_L_PROJCODE + @ERR_PUR_L_PARTTYPE +
				@ERR_PUR_L_REFCODE + @ERR_PUR_L_ACCTCODE + @ERR_PUR_L_LINENO +
				@ERR_PUR_TAXCODE + @ERR_PUR_STATUS

---

declare @ERR_PUR_R_POPART	int
declare @ERR_PUR_R_CONFIRM	int
declare @ERR_PUR_R_POLINEERR	int

declare @ERR_PUR_R_ALL		int

select	@ERR_PUR_R_POPART	= 0x00010000
select  @ERR_PUR_R_CONFIRM	= 0x00020000
select 	@ERR_PUR_R_POLINEERR	= 0x00040000

/* RDS */
-- select	@ERR_PUR_R_ALL		= @ERR_PUR_R_POPART + @ERR_PUR_R_CONFIRM + @ERR_PUR_R_POLINEERR
select	@ERR_PUR_R_ALL		= @ERR_PUR_R_POPART + @ERR_PUR_R_POLINEERR
/* END RDS */

-- set error bits on
UPDATE 	impur_vw
set 	record_status_1 = 0,
	record_status_2 = 0
from 	impur_vw,
	#t99
where 	impur_vw.record_id_num = #t99.record_id_num

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 | @ERR_PUR_HDR_1,
	record_status_2 = record_status_2 | @ERR_PUR_HDR_2
from 	impur_hdr_vw,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num

UPDATE 	impur_line_vw
set 	record_status_1 = record_status_1 | @ERR_PUR_LINE_1
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num

UPDATE 	impur_rel_vw
set	record_status_2 = record_status_2 | @ERR_PUR_R_ALL
from 	impur_rel_vw,
	#t99
where	impur_rel_vw.record_id_num = #t99.record_id_num


-- validate order header
select 	@w_highest_po_no = last_no
from 	next_po_no

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_PONO
from 	impur_hdr_vw,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(	po_key >= 0
	and 	po_key <= @w_highest_po_no )

UPDATE 	impur_hdr_vw
set 	po_no = convert(varchar(10),po_key)
from 	impur_hdr_vw,
	#t99
where	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(record_status_1 & @ERR_PUR_PONO) = 0

update	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_STATUS
from 	impur_hdr_vw,
	#t99
where	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.status in ('O','C','H')

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_PRINTFLAG
from 	impur_hdr_vw,
	#t99
where	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.printed in ('H','N','P','Y')

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_VENDORCODE
from 	impur_hdr_vw,
	apvend,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.vendor_no = apvend.vendor_code

-- hdr defaults based on vendor code
/*
update	impur_hdr_vw
set	ship_name = apv.addr1
	,ship_address1 = apv.addr2
	,ship_address2 = apv.addr3
	,ship_address3 = apv.addr4
	,ship_address4 = apv.addr5
from	impur_hdr_vw,
	#t99,
	apvend apv
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(impur_hdr_vw.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	impur_hdr_vw.vendor_no = apv.vendor_code
and 	impur_hdr_vw.ship_address1 = ''
and 	impur_hdr_vw.ship_address1 = ''
and 	impur_hdr_vw.ship_address3 = ''
and 	impur_hdr_vw.ship_address4 = ''
and 	impur_hdr_vw.ship_address5 = ''
*/


UPDATE 	impur_hdr_vw
set	tax_code = apv.tax_code
from 	impur_hdr_vw hdr,
	#t99,
	apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	hdr.vendor_no = apv.vendor_code
and 	(	hdr.tax_code is null
	or	hdr.tax_code = ''
	)

update	hdr
set	hdr.terms = apv.terms_code
from 	impur_hdr_vw hdr,
	#t99,
        apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	hdr.vendor_no = apv.vendor_code
and 	(	hdr.terms is null
	or	hdr.terms = ''
	)

UPDATE 	impur_hdr_vw
set 	ship_via = apv.freight_code
from 	impur_hdr_vw hdr,
	#t99,
        apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	hdr.vendor_no = apv.vendor_code
and 	(	hdr.ship_via is null
	or	hdr.ship_via = ''
	)

UPDATE 	impur_hdr_vw
set	fob = apv.fob_code
from 	impur_hdr_vw hdr,
	#t99,
        apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	hdr.vendor_no = apv.vendor_code
and 	(	hdr.fob is null
	or	hdr.fob = ''
	)

UPDATE 	impur_hdr_vw
set 	posting_code = apv.posting_code
from 	impur_hdr_vw hdr,
	#t99,
        apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and 	hdr.vendor_no = apv.vendor_code
and 	(	hdr.posting_code is null
	or	hdr.posting_code = ''
	)

UPDATE 	impur_hdr_vw
   SET 	rate_type_home = apv.rate_type_home
  FROM 	impur_hdr_vw hdr, #t99, apvend apv
 WHERE 	hdr.record_id_num = #t99.record_id_num
   AND 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
   AND 	hdr.vendor_no = apv.vendor_code
   AND  ISNULL(DATALENGTH(RTRIM(LTRIM(hdr.rate_type_home))),0) = 0

UPDATE 	impur_hdr_vw
   SET 	rate_type_oper = apv.rate_type_oper
  FROM 	impur_hdr_vw hdr, #t99, apvend apv
 WHERE 	hdr.record_id_num = #t99.record_id_num
   AND 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
   AND 	hdr.vendor_no = apv.vendor_code
   AND  ISNULL(DATALENGTH(RTRIM(LTRIM(hdr.rate_type_oper))),0) = 0

UPDATE 	impur_hdr_vw
   SET 	curr_key = apv.nat_cur_code
  FROM 	impur_hdr_vw hdr, #t99, apvend apv
 WHERE 	hdr.record_id_num = #t99.record_id_num
   AND 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
   AND 	hdr.vendor_no = apv.vendor_code
   AND  ISNULL(DATALENGTH(RTRIM(LTRIM(hdr.curr_key))),0) = 0


/*
** Update multi currency information
*/
CREATE TABLE #rates ( 
	from_currency varchar(8), 
	to_currency varchar(8), 
	rate_type varchar(8), 
	date_applied int, 
	rate float )

INSERT INTO #rates
   SELECT hdr.curr_key, @home_currency, hdr.rate_type_home, DATEDIFF(DD, '1/1/80', date_of_order)+722815, 0.0
     FROM impur_hdr_vw hdr, #t99
    WHERE hdr.record_id_num = #t99.record_id_num

EXEC CVO_Control..mcrates_sp

IF (@p_debug_level >= 3)  
BEGIN
	SELECT 'Dump of hdr.rate_type_home #rates table'
	SELECT * FROM #rates
END

UPDATE impur_hdr_vw
   SET curr_factor = #rates.rate
  FROM impur_hdr_vw hdr, #t99, #rates
 WHERE hdr.record_id_num = #t99.record_id_num
   AND hdr.curr_key = #rates.from_currency
   AND hdr.rate_type_home = #rates.rate_type
   AND DATEDIFF(DD, '1/1/80', date_of_order)+722815 = #rates.date_applied
   AND hdr.curr_factor IS NULL
   AND #rates.rate <> 0.0

DELETE #rates

INSERT INTO #rates
   SELECT hdr.curr_key, @oper_currency, hdr.rate_type_oper, DATEDIFF(DD, '1/1/80', date_of_order)+722815, 0.0
     FROM impur_hdr_vw hdr, #t99
    WHERE hdr.record_id_num = #t99.record_id_num

EXEC CVO_Control..mcrates_sp

IF (@p_debug_level >= 3)  
BEGIN
	SELECT 'Dump of hdr.rate_type_oper #rates table'
	SELECT * FROM #rates
END

UPDATE impur_hdr_vw
   SET oper_factor = #rates.rate
  FROM impur_hdr_vw hdr, #t99, #rates
 WHERE hdr.record_id_num = #t99.record_id_num
   AND hdr.curr_key = #rates.from_currency
   AND hdr.rate_type_oper = #rates.rate_type
   AND DATEDIFF(DD, '1/1/80', date_of_order)+722815 = #rates.date_applied
   AND hdr.oper_factor IS NULL
   AND #rates.rate <> 0.0


DELETE #rates

INSERT INTO #rates
   SELECT hdr.curr_key, @home_currency, hdr.rate_type_home, DATEDIFF(DD, '1/1/80', hdr.date_of_order)+722815, 0.0
     FROM impur_hdr_vw hdr, impur_line_vw line, #t99
    WHERE line.record_id_num = #t99.record_id_num
      AND hdr.po_key = line.po_key

EXEC CVO_Control..mcrates_sp

IF (@p_debug_level >= 3)  
BEGIN
	SELECT 'Dump of line.rate_type_home #rates table'
	SELECT * FROM #rates
END

UPDATE impur_line_vw
   SET curr_factor = #rates.rate
  FROM impur_hdr_vw hdr, impur_line_vw line, #t99, #rates
 WHERE line.record_id_num = #t99.record_id_num
   AND line.curr_factor IS NULL
   AND hdr.po_key = line.po_key
   AND hdr.curr_key = #rates.from_currency
   AND hdr.rate_type_home = #rates.rate_type
   AND DATEDIFF(DD, '1/1/80', date_of_order)+722815 = #rates.date_applied
   AND #rates.rate <> 0.0


DELETE #rates

INSERT INTO #rates
   SELECT hdr.curr_key, @oper_currency, hdr.rate_type_oper, DATEDIFF(DD, '1/1/80', hdr.date_of_order)+722815, 0.0
     FROM impur_hdr_vw hdr, impur_line_vw line, #t99
    WHERE line.record_id_num = #t99.record_id_num
      AND hdr.po_key = line.po_key

EXEC CVO_Control..mcrates_sp

IF (@p_debug_level >= 3)  
BEGIN
	SELECT 'Dump of line.rate_type_oper #rates table'
	SELECT * FROM #rates
END

UPDATE impur_line_vw
   SET oper_factor = #rates.rate
  FROM impur_hdr_vw hdr, impur_line_vw line, #t99, #rates
 WHERE line.record_id_num = #t99.record_id_num
   AND line.oper_factor IS NULL
   AND hdr.po_key = line.po_key
   AND hdr.curr_key = #rates.from_currency
   AND hdr.rate_type_oper = #rates.rate_type
   AND DATEDIFF(DD, '1/1/80', date_of_order)+722815 = #rates.date_applied
   AND #rates.rate <> 0.0

UPDATE impur_line_vw
   SET curr_cost = line.curr_factor * line.unit_cost
  FROM impur_line_vw line, #t99
 WHERE line.record_id_num = #t99.record_id_num
   AND line.curr_cost IS NULL
   AND line.curr_factor > 0.0

UPDATE impur_line_vw
   SET curr_cost = line.unit_cost / ABS(line.curr_factor) 
  FROM impur_line_vw line, #t99
 WHERE line.record_id_num = #t99.record_id_num
   AND line.curr_cost IS NULL
   AND line.curr_factor < 0.0

UPDATE impur_line_vw
   SET oper_cost = line.oper_factor * line.unit_cost
  FROM impur_line_vw line, #t99
 WHERE line.record_id_num = #t99.record_id_num
   AND line.oper_cost IS NULL
   AND line.oper_factor > 0.0

UPDATE impur_line_vw
   SET oper_cost = line.unit_cost / ABS(line.oper_factor) 
  FROM impur_line_vw line, #t99
 WHERE line.record_id_num = #t99.record_id_num
   AND line.oper_cost IS NULL
   AND line.oper_factor < 0.0

DROP TABLE #rates

------
UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_SHIP_TO_NO
from 	impur_hdr_vw,
	locations,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.ship_to_no = locations.location
and 	impur_hdr_vw.location <> 'DROP'

-- if the ship to is valid, then overwrite the address
-- with the location address information
UPDATE 	impur_hdr_vw
set 	ship_name = loc.name,
	ship_address1 = loc.addr1,
	ship_address2 = loc.addr2,
	ship_address3 = loc.addr3,
	ship_address4 = loc.addr4,
	ship_address5 = loc.addr5
from 	impur_hdr_vw hdr,
	#t99,
	locations loc
where 	hdr.record_id_num = #t99.record_id_num
and 	hdr.ship_to_no = loc.location
and 	hdr.ship_to_no <> 'DROP'
and 	(hdr.record_status_1 & @ERR_PUR_SHIP_TO_NO) = 0		/* RDS */
and 	hdr.ship_address1 <= ' '
and 	hdr.ship_address1 <= ' '
and 	hdr.ship_address3 <= ' '
and 	hdr.ship_address4 <= ' '
and 	hdr.ship_address5 <= ' '

-- the only other valid possibility is for this to be a
-- drop shipment, in that case overwrite the address info
-- with the infor from the vendor.

update	hdr
set	hdr.record_status_1 = hdr.record_status_1 ^ @ERR_PUR_SHIP_TO_NO
from 	impur_hdr_vw hdr,
	#t99,
	apvend apv
where 	hdr.record_id_num = #t99.record_id_num
and 	hdr.ship_to_no = 'DROP'
and 	(hdr.record_status_1 & @ERR_PUR_VENDORCODE) = 0
and	(hdr.record_status_1 & @ERR_PUR_SHIP_TO_NO) > 0


update	hdr
set 	hdr.record_status_1 = record_status_1 ^ @ERR_PUR_SHIP_VIA
from 	impur_hdr_vw hdr,
	#t99,
	arshipv
where 	hdr.record_id_num = #t99.record_id_num
and 	hdr.ship_via = arshipv.ship_via_code

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_FOB
from 	impur_hdr_vw,
	#t99,
	arfob
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.fob = arfob.fob_code

UPDATE 	impur_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_PUR_TAXCODE
from 	impur_hdr_vw,
	#t99,
	aptax
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.tax_code = aptax.tax_code

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_LOC
from 	impur_hdr_vw,
	#t99,
	locations
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.location = locations.location

UPDATE 	impur_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_PUR_BUYER
from 	impur_hdr_vw,
	#t99,
	buyers
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.buyer = buyers.kys

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_BUYER
from 	impur_hdr_vw,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(record_status_1 & @ERR_PUR_BUYER) > 0
and 	(	buyer <= ' '
	or 	buyer is null)

UPDATE 	impur_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_PUR_TERMS
from 	impur_hdr_vw,
	#t99,
	apterms
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.terms = apterms.terms_code

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_POSTN_CODE
from 	impur_hdr_vw,
	#t99,
	apaccts
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.posting_code = apaccts.posting_code

-- turn the HOLDCODE error off where the status does not
-- indicate a hold in effect.
UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_HOLDCODE
from 	impur_hdr_vw,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.status <> 'H'
and 	(record_status_1 & @ERR_PUR_STATUS) = 0

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_HOLDCODE
from 	impur_hdr_vw,
	#t99,
	adm_pohold
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(record_status_1 & @ERR_PUR_HOLDCODE) > 0
and 	impur_hdr_vw.hold_reason = adm_pohold.hold_code

UPDATE 	impur_hdr_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_CURR
from 	impur_hdr_vw,
	#t99,
	glcurr_vw
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.curr_key = glcurr_vw.currency_code


UPDATE 	impur_hdr_vw
set	record_status_1 = record_status_1 ^ @ERR_PUR_DUP
from 	(	select 		count(*) as _count,
				po_key
		from 		impur_hdr_vw
		where 		company_code = @w_cc
		and 		process_status = 0
		group by	po_key
		having		count(*) = 1
		) as singles,
	#t99
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.po_key = singles.po_key


update	impur_hdr_vw
set 	record_status_1 = record_status_1 + @ERR_PUR_DUP
from 	impur_hdr_vw,
	#t99,
	purchase
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(record_status_1 & @ERR_PUR_DUP) = 0
and 	impur_hdr_vw.po_key = purchase.po_key

UPDATE 	impur_hdr_vw
set 	impur_hdr_vw.record_status_1 = impur_hdr_vw.record_status_1 ^ @ERR_PUR_NOLIN
from 	impur_hdr_vw,
	#t99,
	impur_line_vw
where 	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	impur_hdr_vw.po_key = impur_line_vw.po_key
and 	impur_line_vw.company_code = @w_cc
and 	impur_line_vw.process_status = 0

UPDATE 	impur_hdr_vw
set	record_status_1 = impur_hdr_vw.record_status_1 ^ @ERR_PUR_SHIP_NAME
from 	impur_hdr_vw,
	#t99
where 	impur_hdr_vw.record_status_1 = #t99.record_id_num


UPDATE 	impur_hdr_vw
   SET 	record_status_2 = impur_hdr_vw.record_status_2 | @ERR_PUR_MC
  FROM 	impur_hdr_vw, #t99
 WHERE 	impur_hdr_vw.record_id_num = #t99.record_id_num
   AND	(impur_hdr_vw.curr_factor IS NULL OR impur_hdr_vw.oper_factor IS NULL)


UPDATE 	impur_line_vw
   SET 	record_status_2 = impur_line_vw.record_status_2 | @ERR_PUR_MC
  FROM 	impur_line_vw, #t99
 WHERE 	impur_line_vw.record_id_num = #t99.record_id_num
   AND	(impur_line_vw.curr_factor IS NULL OR impur_line_vw.oper_factor IS NULL)



-- line validations

update	impur_line_vw
set	record_status_1 = record_status_1 ^ @ERR_PUR_STATUS
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	(impur_line_vw.record_status_1 & @ERR_PUR_STATUS) > 0
and 	impur_line_vw.status in ( 'O','C','H' )

-- if the tax code is blank, the as the eDist client does
-- assume that the tax code for the line, will be the same
-- as the tax code for the header
UPDATE 	impur_line_vw
set 	tax_code = impur_hdr_vw.tax_code
from 	impur_line_vw,
	#t99,
	impur_hdr_vw
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.po_key = impur_hdr_vw.po_key
and 	(impur_hdr_vw.record_status_1 & @ERR_PUR_DUP) = 0
and 	(	impur_line_vw.tax_code = ''
	or 	impur_line_vw.tax_code is null
	)

update	impur_line_vw
set 	record_status_1 = record_status_1 ^  @ERR_PUR_TAXCODE
from 	impur_line_vw,
	#t99,
	aptax
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	(impur_line_vw.record_status_1 & @ERR_PUR_TAXCODE) > 0
and 	impur_line_vw.tax_code = aptax.tax_code

SELECT @prev_po_key = -1

DECLARE part_no_cursor INSENSITIVE CURSOR FOR 
  SELECT im.po_key, im.record_id_num
    FROM impur_line_vw im, #t99
   WHERE ISNULL(DATALENGTH(RTRIM(LTRIM(part_no))),0) = 0
     AND im.record_id_num = #t99.record_id_num
   ORDER BY po_key

OPEN part_no_cursor
  FETCH NEXT FROM part_no_cursor INTO @po_key, @record_id_num
					
WHILE (@@FETCH_STATUS <> -1)
BEGIN
	IF @@FETCH_STATUS <> -2
	BEGIN
		IF @po_key <> @prev_po_key
		BEGIN
			SELECT @prev_po_key = @po_key, @cntr = 0
		END

		IF @cntr < 10
			SELECT @ext = '0' + CONVERT(CHAR,@cntr)
		ELSE
			SELECT @ext = CONVERT(CHAR,@cntr)

		UPDATE impur_line_vw
		   SET part_no = RTRIM(LTRIM(@default_part_no)) + @ext
		 WHERE record_id_num = @record_id_num
		SELECT @cntr = @cntr + 1
	END

FETCHNEXT:
  FETCH NEXT FROM part_no_cursor INTO @po_key, @record_id_num
END

CLOSE part_no_cursor
DEALLOCATE part_no_cursor


update	impur_line_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_L_PARTNO
from 	impur_line_vw,
	#t99,
	inv_master
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.part_no = inv_master.part_no
and 	inv_master.obsolete = 0
and 	inv_master.void = 'N'

UPDATE 	impur_line_vw
set 	record_status_1 = lin.record_status_1 ^ @ERR_PUR_L_LOCATION,
	description = im.description,
	lb_tracking = im.lb_tracking,
	conv_factor = im.conv_factor,		/* RDS */
	weight_ea = im.weight_ea			/* RDS */
from 	impur_line_vw lin,
	#t99,
	inv_list il,
	inv_master im
where	lin.record_id_num = #t99.record_id_num
and 	lin.part_no = il.part_no
and 	lin.location = il.location
and 	lin.part_no = im.part_no
and 	(lin.record_status_1 & @ERR_PUR_L_PARTNO) = 0

-- if no unit of measure is supplied then, get the default
-- unit of measure off off the item master (inv_master)
UPDATE 	impur_line_vw
set 	uom = im.uom
from 	impur_line_vw lin,
	#t99,
	inv_master im
where	lin.record_id_num = #t99.record_id_num
and 	lin.part_no = im.part_no
and 	(	lin.uom = ''
	or 	lin.uom is null
        )

update	impur_line_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_L_UNITMEASURE
from 	impur_line_vw,
	#t99,
	inv_master
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.part_no = inv_master.part_no
and 	impur_line_vw.uom = inv_master.uom
and 	(impur_line_vw.record_status_1 & @ERR_PUR_L_PARTNO) = 0

UPDATE 	impur_line_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_L_UNITMEASURE
from 	impur_line_vw,
	#t99,
	inv_master,
	uom_table
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	(impur_line_vw.record_status_1 & @ERR_PUR_L_UNITMEASURE) > 0
and 	impur_line_vw.part_no = inv_master.part_no
and 	(	impur_line_vw.part_no = uom_table.item
	or	uom_table.item = 'STD' )
and 	inv_master.uom = uom_table.std_uom
and 	impur_line_vw.uom = uom_table.alt_uom


update	impur_line_vw
set 	record_status_1 = record_status_1 ^ @ERR_PUR_L_PARTTYPE
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.type in ('P','M')

-- check to see if the po_key = a valid po_key on a header record, if so
-- then check to see if the only error on that header is a @ERR_PUR_INVALID_LIN
-- error, then it can be assumed that the ERR_PUR_L_ORD_NO error can be turned off
UPDATE 	impur_line_vw
set 	record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ORDNO,
	impur_line_vw.po_no = convert(varchar(10),impur_line_vw.po_key)
from 	impur_line_vw,
	#t99,
	impur_hdr_vw
where	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.po_key = impur_hdr_vw.po_key
and 	impur_hdr_vw.company_code = @w_cc
and 	impur_hdr_vw.process_status = 0
and 	impur_hdr_vw.record_status_2 = 0
and 	(	impur_hdr_vw.record_status_1 = 0
	or 	impur_hdr_vw.record_status_1 = @ERR_PUR_INVLD_LIN
	)

-- UPDATE and check the account_no
-- for parts of type 'P' then the account_no will come from
-- from the posting code on the header.
UPDATE 	impur_line_vw
set 	account_no = in_account.inv_acct_code,
	impur_line_vw.record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ACCTCODE
from 	impur_line_vw,
	#t99,
	in_account,
	inv_list
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.part_no = inv_list.part_no
and 	impur_line_vw.location = inv_list.location
and 	impur_line_vw.type = 'P'
and 	inv_list.acct_code = in_account.acct_code

UPDATE 	impur_line_vw
set 	record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ACCTCODE
from 	impur_line_vw,
	#t99,
	glchart
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.type = 'M'
and 	impur_line_vw.account_no = glchart.account_code
and 	glchart.inactive_flag = 0

-- turn off errors where the part_no is invalid, because they will be meaningless
update	impur_line_vw
set	impur_line_vw.record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_ACCTCODE
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	(impur_line_vw.record_status_1 & @ERR_PUR_L_PARTNO) > 0
and 	(impur_line_vw.record_status_1 & @ERR_PUR_L_ACCTCODE) > 0
and 	impur_line_vw.type = 'P'


update	impur_line_vw
set 	impur_line_vw.record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_PROJCODE
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num

UPDATE 	impur_line_vw
set 	record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_REFCODE
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num


UPDATE 	impur_line_vw
set	record_status_1 = impur_line_vw.record_status_1 ^ @ERR_PUR_L_LINENO
from 	(	select	count(*) as _count,
			po_key,
			line
		from 	impur_line_vw
		where	impur_line_vw.company_code = @w_cc
		and 	impur_line_vw.process_status = 0
		and 	impur_line_vw.line > 0
		group by po_key,line
		having	count(*) = 1
	) as v2,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	impur_line_vw.po_key = v2.po_key
and 	impur_line_vw.line = v2.line

DELETE impur_rel_vw
  FROM impur_rel_vw rel, impur_line_vw line, #t99
 WHERE line.record_id_num = #t99.record_id_num
   AND line.company_code = rel.company_code
   AND line.part_no = rel.part_no
   AND line.po_key = rel.po_key
  

INSERT INTO impur_rel_vw (po_no, po_key, type, part_no, lb_tracking, location, rel_date, prev_qty, qty_ordered, qty_received, conv_factor, status, batch_no, dirty_flag, record_status_1, record_status_2, process_status, company_code, record_type)
  SELECT po_no, line.po_key, type, line.part_no, lb_tracking, location, rel_date, prev_qty, qty_ordered, qty_received, conv_factor, status, batch_no, 1, 0, 0, 0, company_code, 256
    FROM impur_line_vw line, #t99
   WHERE #t99.record_id_num = line.record_id_num

select	po_key,
	part_no
into 	#t_lin_dups
from 	impur_line_vw
where 	company_code = @w_cc
and	process_status = 0
group by po_key,part_no
having 	count(*) > 1

-- turn error bit on for duplicates
UPDATE 	impur_line_vw
set 	record_status_2 = lin.record_status_2 | @ERR_PUR_L_PARTDUP
from 	impur_line_vw lin
	,#t_lin_dups
	,#t99
where 	lin.record_id_num = #t99.record_id_num
and 	lin.po_key = #t_lin_dups.po_key
and 	lin.part_no = #t_lin_dups.part_no

-------------------------------------
-- end of line validations
-------------------------------------

-------------------------------------
-- purchase order release validations
-------------------------------------
update	rel
set	rel.record_status_2 = rel.record_status_2 ^ @ERR_PUR_R_POPART
from 	impur_rel_vw rel,
	#t99,
	impur_line_vw lin
where	rel.record_id_num = #t99.record_id_num
and 	rel.po_key = lin.po_key
and 	rel.part_no = lin.part_no
and 	lin.company_code = @w_cc
and 	lin.process_status = 0

-------------------------------------
-- end of purchase order release validations
-------------------------------------

-- determine the po_keys that have lines that are in error
select 	impur_line_vw.po_key
into 	#polins
from 	impur_line_vw,
	#t99
where 	impur_line_vw.record_id_num = #t99.record_id_num
and 	(	impur_line_vw.record_status_1 > 0
	or 	impur_line_vw.record_status_2 > 0
	)
and 	impur_line_vw.process_status = 0
group by po_key

if @p_debug_level > 0
begin
	select * from #polins
end

-- set the error bit on for all headers that have lines that are in error
UPDATE 	impur_hdr_vw
set	record_status_1 = impur_hdr_vw.record_status_1 | @ERR_PUR_INVLD_LIN
from 	#polins,
	#t99,
	impur_hdr_vw
where	impur_hdr_vw.record_id_num = #t99.record_id_num
and 	(impur_hdr_vw.record_status_1 & @ERR_PUR_INVLD_LIN) = 0
and 	impur_hdr_vw.po_key = #polins.po_key


GO
GRANT EXECUTE ON  [dbo].[imPurVal_e7_sp] TO [public]
GO
