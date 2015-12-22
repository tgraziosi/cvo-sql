SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE procedure [dbo].[imInvVal_e7_sp] (
    @p_batchno  		int = NULL,
    @p_start_rec    		int = 0,
    @p_end_rec 			int = 0,
    @p_record_type		int = 0x000000FF,
    @p_debug_level 		int = 0
) as

declare @w_cc					varchar(8)
declare @w_start                int
declare @w_end                  int

select @w_start = 0
select @w_end = 0

select @w_cc = company_code from glco

if @p_debug_level > 0
begin
	select @p_batchno as Batch, @w_start as Start_Record, @w_end as End_Record
end

create table #t1 (
	record_id_num			int
	constraint t1_key unique nonclustered (record_id_num)
)


if @p_batchno is not NULL
begin

	print 'batch is not null'

	select 		@w_start = min(record_id_num)
	from 		iminvmast_vw
	where 		company_code = @w_cc
	and 		batch_no = @p_batchno
	and 	 	process_status = 0

	if @@rowcount = 0
	begin
		select @w_start = @p_start_rec
		select @w_end = @p_end_rec
	end
	else
	begin
		select 		@w_end = max(record_id_num)
		from 		iminvmast_vw
		where 		company_code = @w_cc
		and 		batch_no = @p_batchno
		and 	 	process_status = 0

		if @p_end_rec < @w_end
		begin
		    select @w_end = @p_end_rec
		end

		if @p_start_rec > @w_start
		begin
		    select @w_start = @p_start_rec
		end
	end

end
else
begin
	if @p_start_rec > 0
	begin
		print 'p_start_rec > 0'

		select 		@w_start = @p_start_rec
	end
	else
	begin
		print 'p_start_rec = 0'

		select 		@w_start = min(record_id_num)
		from 		iminvmast_vw
		where 		company_code = @w_cc
		and 		process_status = 0

		print '@w_start=' + convert(char(30),@w_start)
	end

	if @p_end_rec > 0
	begin
		select @w_end = @p_end_rec
	end
	else
	begin
		select 		@w_end = max(record_id_num)
		from 		iminvmast_vw
		where 		company_code = @w_cc
		and 		process_status = 0
	end
end

insert 	into #t1
select 	record_id_num
from 	iminvmast_vw
where	company_code = @w_cc
and 	process_status = 0
and 	record_id_num >= @w_start
and 	record_id_num <= @w_end

if @p_debug_level > 0
begin
	select @w_cc as company_code, @p_batchno as Batch, @w_start as Start_Record, @w_end as End_Record
end

if @p_debug_level >= 6
begin
	select * from #t1
	print 'Exiting on debug request'
	return
end


declare @dt 			datetime
declare @w_dmsg 		varchar(255)

declare @RECTYPE_INVMST         int
declare @RECTYPE_INVMST_BASE    int
declare @RECTYPE_INVMST_PURC    int
declare @RECTYPE_INVMST_COST    int
declare @RECTYPE_INVMST_PRIC    int
declare @RECTYPE_INVMST_ACCT    int

select  @RECTYPE_INVMST_BASE    = 0x00000001
select  @RECTYPE_INVMST_PURC    = 0x00000002
select  @RECTYPE_INVMST_COST    = 0x00000004
select  @RECTYPE_INVMST_PRIC    = 0x00000008
select  @RECTYPE_INVMST_ACCT    = 0x00000010
select  @RECTYPE_INVMST         = 0x0000001F

declare @RECTYPE_INVLOC         int
declare @RECTYPE_INVLOC_BASE    int
declare @RECTYPE_INVLOC_COST    int
declare @RECTYPE_INVLOC_STCK    int

select  @RECTYPE_INVLOC_BASE    = 0x00000100
select  @RECTYPE_INVLOC_COST    = 0x00000200
select  @RECTYPE_INVLOC_STCK    = 0x00000400
select  @RECTYPE_INVLOC         = @RECTYPE_INVLOC_BASE + @RECTYPE_INVLOC_COST + @RECTYPE_INVLOC_STCK

declare @RECTYPE_INVBOM         int
select  @RECTYPE_INVBOM         = 0x00001000

declare @RECTYPE_INVLSB         int
select  @RECTYPE_INVLSB         = 0x00010000


declare	@ERRS_BASIC		int
declare @ERR_UOM		int
declare @ERR_CATEGORY		int
declare @ERR_TYPE_CODE		int
declare @ERR_STATUS		int
declare @ERR_COMMTYPE		int
declare @ERR_CYCLETYPE		int
declare @ERR_FREIGHTCLS		int
declare	@ERR_INVCOST_METH	int
declare @ERR_NOLOC		int

declare @ERR_ACCOUNT		int
declare @ERR_TAXCODE		int
declare @ERR_ACCT_NOMAST	int

declare @ERRS_PURCHASING	int
declare @ERR_VENDOR		int
declare @ERR_BUYER		int
declare @ERR_PUR_NOMAST		int

declare @ERRS_LOC		int
declare	@ERR_LOC		int
declare @ERR_LOC_NOMAST		int
declare @ERR_LOC_ACCTCODE   	int
declare @ERR_LOC_INVCODE    	int
declare @ERR_LOC_DUP		int

declare	@ERRS_BUILDPLAN		int
declare	@ERR_ACTIVE_FLAG	int
declare	@ERR_BPLOC		int
declare	@ERR_INVLDPART		int
declare	@ERR_CONSTRAIN		int
declare	@ERR_FIXED		int
declare @ERR_INVLD_BPPART	int
declare @ERR_BP_UOM		int
declare @ERR_BP_SEQ		int
declare @ERR_INCOMPTYPES	int

select	@ERR_UOM		= 	0x00000001
select 	@ERR_CATEGORY		=	0x00000002
select	@ERR_TYPE_CODE		= 	0x00000004
select	@ERR_STATUS		=	0x00000008
select	@ERR_COMMTYPE		=	0x00000010
select	@ERR_CYCLETYPE		=	0x00000020
select 	@ERR_FREIGHTCLS		=	0x00000040
select	@ERR_NOLOC		= 	0x00000080
select	@ERR_INVCOST_METH	=	0x00000100
select	@ERR_ACCOUNT		=	0x00001000
select	@ERR_TAXCODE		=	0x00002000

select 	@ERRS_BASIC		= 	@ERR_UOM +            @ERR_CATEGORY +     @ERR_TYPE_CODE +    @ERR_STATUS +
                                	@ERR_COMMTYPE +       @ERR_CYCLETYPE +    @ERR_FREIGHTCLS +   @ERR_NOLOC +
                                	@ERR_INVCOST_METH +    @ERR_ACCOUNT +     @ERR_TAXCODE

select	@ERR_VENDOR		=	0x00010000
select	@ERR_BUYER		=	0x00020000
select  @ERR_PUR_NOMAST		= 	0x00040000
select	@ERRS_PURCHASING	=	@ERR_VENDOR + @ERR_BUYER + @ERR_PUR_NOMAST

select 	@ERR_LOC		= 	0x00100000
select	@ERR_LOC_NOMAST		= 	0x00200000
select  @ERR_LOC_ACCTCODE   	=   	0x00400000
select  @ERR_LOC_INVCODE    	=   	0x00800000
-- used ERR_UOM as well
select 	@ERRS_LOC		=	@ERR_LOC + @ERR_LOC_NOMAST + @ERR_UOM + @ERR_LOC_ACCTCODE

select 	@ERR_LOC_DUP		= 	0x00000100

select	@ERR_ACTIVE_FLAG	=	0x01000000
select	@ERR_BPLOC		=	0x02000000
select	@ERR_INVLDPART		=	0x04000000
select	@ERR_CONSTRAIN		=	0x08000000
select 	@ERR_FIXED		=	0x10000000
select  @ERR_INCOMPTYPES	= 	0x00000200
select 	@ERRS_BUILDPLAN		=	@ERR_ACTIVE_FLAG + @ERR_BPLOC + @ERR_INVLDPART + @ERR_CONSTRAIN + @ERR_FIXED + @ERR_INCOMPTYPES

select  @ERR_INVLD_BPPART	= 	0x00000040
select  @ERR_BP_UOM		= 	0x00000080
select 	@ERR_BP_SEQ		= 	0x00000400


declare @ERR_LBS_NOLOC      	int
declare @ERR_LBS_UOM        	int
declare @ERR_LBS_CODE       	int
declare @ERR_LBS_LBTRACK    	int
declare @ERR_LBS_NEGQTY		int
declare @ERR_LBS_NULLBINNO	int
declare @ERR_LBS_NULLLOTSER	int
declare	@ERR_LBS_MSTRNOLBTRAK	int
--
declare @ERRS_LBS           	int

select  @ERR_LBS_NOLOC     	=	0x00000001
select  @ERR_LBS_UOM        	=	0x00000002
select  @ERR_LBS_CODE       	=	0x00000004
select	@ERR_LBS_LBTRACK    	= 	0x00000008
select 	@ERR_LBS_NEGQTY		= 	0x00000200
select 	@ERR_LBS_NULLBINNO	= 	0x00000800
select	@ERR_LBS_NULLLOTSER	= 	0x00001000
select 	@ERR_LBS_MSTRNOLBTRAK	= 	0x00002000
select  @ERRS_LBS           	=   	@ERR_LBS_NOLOC + @ERR_LBS_UOM + @ERR_LBS_CODE + @ERR_LBS_LBTRACK + @ERR_LBS_NEGQTY
					+ @ERR_LBS_NULLBINNO + @ERR_LBS_NULLLOTSER + @ERR_LBS_MSTRNOLBTRAK

declare @ERR_PRIC_NOLOC     	int
declare @ERR_PRIC_UOM       	int
declare @ERRS_PRIC          	int

select  @ERR_PRIC_NOLOC     	=   	0x00000010             -- must be a valid loc, either this table or dest table
select  @ERR_PRIC_UOM       	=   	0x00000020             -- must equal uom on master
select  @ERRS_PRIC          	=   	@ERR_PRIC_NOLOC + @ERR_PRIC_UOM

select @w_cc = company_code from glco

/**************
  test for record_type problems, mask out any bits that are not record types
**************/

-- CLEAR ALL THE ERROR BITS

update 	iminvmast_vw
set	iminvmast_vw.record_status_1 = 0x00000000,
        iminvmast_vw.record_status_2 = 0x00000000
from 	iminvmast_vw,
	#t1
where   iminvmast_vw.record_id_num = #t1.record_id_num

-- TURN ON THE INV MASTER ERRROR BITS

update 	iminvmast_vw
set 	iminvmast_vw.record_status_1 = @ERRS_BASIC
from 	iminvmast_vw,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0


-- TURN ON LOT/STOCK ERROR BITS
update	iminvmast_lbs_vw
set	iminvmast_lbs_vw.record_status_1 = iminvmast_lbs_vw.record_status_1 | @ERR_LOC_NOMAST
from 	iminvmast_lbs_vw,
	#t1
where 	iminvmast_lbs_vw.record_id_num = #t1.record_id_num
and 	iminvmast_lbs_vw.record_type = @RECTYPE_INVLSB

update  iminvmast_lbs_vw
set     iminvmast_lbs_vw.record_status_2 = @ERRS_LBS
from 	iminvmast_lbs_vw,
	#t1
where   iminvmast_lbs_vw.record_id_num = #t1.record_id_num

-- TURN ON PRICING ERROR BITS

update  iminvmast_pric_vw
set     record_status_2 = record_status_2 | @ERRS_PRIC
from 	iminvmast_pric_vw,
	#t1
where   iminvmast_pric_vw.record_id_num = #t1.record_id_num



-- TURN ON BUILDPLAN ERROR BITS #1
update 	iminvmast_vw
set	iminvmast_vw.record_status_1 = iminvmast_vw.record_status_1 | @ERRS_BUILDPLAN
from 	iminvmast_vw,
	#t1
where   iminvmast_vw.record_id_num = #t1.record_id_num
and	(iminvmast_vw.record_type & @RECTYPE_INVBOM) > 0

-- TURN ON BUILDPLAN ERROR BITS #2
update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 | (@ERR_INVLD_BPPART + @ERR_BP_UOM)
from 	iminvmast_bom_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num


-- TURN ON THE PURCHASING ERROR BITS

update 	iminvmast_vw
set	iminvmast_vw.record_status_1 = iminvmast_vw.record_status_1 | @ERRS_PURCHASING
from 	iminvmast_vw,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0



update 	iminvmast_vw
set	record_status_1 = record_status_1 | @ERRS_LOC
	--,record_status_2 = record_status_2 | @ERR_LOC_DUP
from 	iminvmast_vw,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVLOC_BASE) > 0

/*
    check to see if the @RECTYPE_INV_STCK bit is set on the record type
    and if so then set the error bits on
*/

update  iminvmast_loc_vw
set     record_status_1 = record_status_1 | @ERR_LOC_INVCODE
from 	iminvmast_loc_vw,
	#t1
where   iminvmast_loc_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_BASE) > 0
and     (iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_STCK) > 0

if @p_debug_level > 0
begin
	select @w_dmsg = convert(varchar(6),@@rowcount)
	select @w_dmsg = @w_dmsg + ' records had ERR_LOC_INVCODE set on'
	print @w_dmsg
   	if @p_debug_level > 1
   	begin
        	select  iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_BASE as is_RECTYPE_INVLOC_BASE,
                	iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_STCK as is_RECTYPE_INVLOC_STCK,
                	record_status_1 & @ERR_LOC_INVCODE as is_set_ERR_LOC_INVCODE
        	from    iminvmast_loc_vw
        	where   company_code = @w_cc
        	and     process_status = 0x00000000
    	end
end


update  iminvmast_Vw
set     record_status_1 = record_status_1 | 0x01000000  -- @ERRS_BUILDPLAN
from 	iminvmast_vw,
	#t1
where   iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_Vw.record_type & @RECTYPE_INVBOM) > 0


update  iminvmast_vw
set     record_status_2 = @ERRS_LBS
from 	iminvmast_vw,
	#t1
where   iminvmast_vw.record_id_num = #t1.record_id_num
and 	(record_type & @RECTYPE_INVLSB) > 0

/*uom */
update	iminvmast_vw
set 	record_status_1 = record_status_1 ^ @ERR_UOM
from 	iminvmast_vw
	,uom_list
	,#t1
where 	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(       ((iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0)
            or  ((iminvmast_vw.record_type & @RECTYPE_INVLOC) > 0)
        )
and	iminvmast_vw.uom = uom_list.uom

/* validate the category */
update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_CATEGORY
from	iminvmast_vw,
	category,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and	iminvmast_vw.category = category.kys

/* validate the type code */
update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_TYPE_CODE
from 	iminvmast_vw,
	part_type,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and 	type_code = part_type.kys

/* validate the status type */
update	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_STATUS
from 	iminvmast_vw,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and	status in ('C','K','H','M','P','Q','R','V')

/* validate the commission type */
update 	iminvmast_vw
set 	record_status_1 = record_status_1 ^ @ERR_COMMTYPE
from 	iminvmast_vw
	,comm_type
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and	iminvmast_vw.comm_type = comm_type.kys

/* validate the inventory cycle types */
update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_CYCLETYPE
from 	iminvmast_vw
	,cycle_types
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and 	iminvmast_vw.cycle_type = cycle_types.kys

/* validate the freight class */
update	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_FREIGHTCLS
from 	iminvmast_vw
	,freight_class
	,#t1
where 	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and     iminvmast_vw.freight_class = freight_class.freight_class

update  iminvmast_mstr_vw
set     record_status_1 = record_status_1 ^ @ERR_FREIGHTCLS
from 	iminvmast_mstr_vw,
	#t1
where   iminvmast_mstr_vw.record_id_num = #t1.record_id_num
and 	(record_status_1 & @ERR_FREIGHTCLS) > 0
and     (    freight_class is null
	or
		freight_class <= ' '
        )

/* validate the inventory costing method */
update	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_INVCOST_METH
from	iminvmast_vw,
	#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0
and 	inv_cost_method  in ('S','A','L','F')

/********************************************************/
/* accounting code										*/
/********************************************************/
update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_ACCOUNT
from 	iminvmast_vw
	,in_account
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0 --RECTYPE_INVMST_ACCT
and 	iminvmast_vw.account = in_account.acct_code

update	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_TAXCODE
from 	iminvmast_vw
	,artax
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_BASE) > 0    --RECTYPE_INVMST_ACCT
and 	iminvmast_vw.tax_code = artax.tax_code

update  iminvmast_vw
set     record_status_1 = record_status_1 ^ @ERR_TAXCODE
from    iminvmast_vw,
	#t1
where   iminvmast_vw.record_id_num = #t1.record_id_num
and 	(record_type & @RECTYPE_INVMST_BASE) > 0
and     (record_status_1 & @ERR_TAXCODE) > 0            -- must still be in error state, checks bit is still set
and     (tax_code is null or tax_code <= ' ')

/********************************************************/
/* purchasing											*/
/********************************************************/
update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_VENDOR
from 	iminvmast_vw
	,apvend
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0
and 	(	iminvmast_vw.vendor = apvend.vendor_code
	or 	iminvmast_vw.vendor = ''
	or 	iminvmast_vw.vendor is null
	)

update 	iminvmast_vw
set	record_status_1 = record_status_1 ^ @ERR_BUYER
from 	iminvmast_vw
	,buyers
	,#t1
where	iminvmast_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_vw.record_type & @RECTYPE_INVMST_PURC) > 0
and 	(  	iminvmast_vw.buyer = buyers.kys
        or 	iminvmast_vw.buyer = ''
        or 	iminvmast_vw.vendor is null
        )

/********************************************************/
/* location validation									*/
/********************************************************/
update	ilv
set	ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC
from 	iminvmast_loc_vw ilv
	,locations
	,#t1
where	ilv.record_id_num = #t1.record_id_num
and 	ilv.location = locations.location

/********************************************************/
/* location acct_code validation   					*/
/* in ERA if set to blank, the value on the header will */
/* be used, this cannot be blank                        */
/********************************************************/
update  ilv
set     ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC_ACCTCODE
from    iminvmast_loc_vw ilv
        ,in_account
	,#t1
where   ilv.record_id_num = #t1.record_id_num
and 	ilv.acct_code = in_account.acct_code

/********************************************************
    if the record_type does not have the @RECTYPE_LOC_STCK
    bit set, then turn off the error bit
    if the RECTYPE_INVLOC_BASE bit is not also set on this
    record then the @ERR_LOC_INVCODE bit will not be set
    and xor'ng it will turn this error bit on
********************************************************/
if @p_debug_level > 0
begin
    ---print convert(varchar(6),@@rowcount) + ' records had ERR_LOC_INVCODE set on'
   if @p_debug_level > 1
   begin
        select  iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_BASE as is_RECTYPE_INVLOC_BASE,
                iminvmast_loc_vw.record_type & @RECTYPE_INVLOC_STCK as is_RECTYPE_INVLOC_STCK,
                record_status_1 & @ERR_LOC_INVCODE as is_set_ERR_LOC_INVCODE
        from    iminvmast_loc_vw
        where   company_code = @w_cc
        and     process_status = 0x00000000
    end
end


update  ilv
set     ilv.record_status_1 = ilv.record_status_1 ^ @ERR_LOC_INVCODE
from    iminvmast_loc_vw ilv
        ,issue_code ic
	,#t1
where   ilv.record_id_num = #t1.record_id_num
and 	ilv.code = ic.code
and     (ilv.record_type & @RECTYPE_INVLOC_STCK) > 0

if @p_debug_level > 0
begin
	select @w_dmsg = convert(varchar(6),@@rowcount)
	select @w_dmsg = @w_dmsg + ' records had ERR_LOC_INVCODE set off'
	print @w_dmsg
	if @p_debug_level > 1
	begin
		select  ilv.record_type,
			ilv.record_type & @RECTYPE_INVLOC_STCK as TYPE_INVLOC_STCK,
                	record_status_1 & @ERR_LOC_INVCODE as is_set_ERR_LOC_INVCODE
        	from    iminvmast_loc_vw ilv
        	where   company_code = @w_cc
        	and     ilv.process_status = 0x00000000
	end
end

/* check for matching records in the production tables */
update 	im1
set 	im1.record_status_2 = im1.record_status_2 ^ @ERR_LOC_DUP
from 	iminvmast_loc_vw im1,
	inv_list,
	#t1
where 	im1.part_no = inv_list.part_no
and 	im1.location = inv_list.location
and 	im1.record_id_num = #t1.record_id_num

/* check for duplicate records in the staging table */

update 	im1
set 	im1.record_status_2 = im1.record_status_2 ^ @ERR_LOC_DUP --256
from 	(
		select	count(*) as _count,
			part_no,
			location
		from 	iminvmast_loc_vw
		where 	company_code = @w_cc
		and 	process_status = 0
		and 	(record_status_2 & @ERR_LOC_DUP) = 0
		group by part_no,location
		having count(*) > 1
	) as duplicates,
	iminvmast_loc_vw im1,
	#t1
where	im1.part_no = duplicates.part_no
and 	im1.location = duplicates.location
and 	im1.record_id_num = #t1.record_id_num

/********************************************************/
-- ensure that for each part master there at least one location
-- update master records
-- determine which error bits are applicable to locations
-- it is necessary to mask out all non locaiton error bits
-- that can be in compound records.
/********************************************************/

select 	@w_start = sum(error_bit)
from 	imerrxref_vw
where 	imtable = 'iminvmast_loc_vw'
and 	status_field = 0

update	im1
set	im1.record_status_1 = im1.record_status_1 ^ @ERR_NOLOC
from 	iminvmast_mstr_vw im1, -- was iminvmast_vw
	iminvmast_loc_vw im2  -- was iminvmast_vw
	,#t1
where	im1.record_id_num = #t1.record_id_num
and 	im1.part_no = im2.part_no
and 	im2.company_code = @w_cc
and     (im1.record_status_1 & @ERRS_BASIC) = @ERR_NOLOC -- mastr has no errors except location, which filter out
and     (im2.record_status_1 & @w_start) =  @ERR_LOC_NOMAST -- loc has no errors except
and 	im2.record_status_2 = 0

/*********************************************************/
-- ensure that for each location record there is a valid
-- master either here or in the destination database
/********************************************************/

/*
select 	im1.record_id_num,im1.part_no,im1.record_status_1
		,im2.record_status_1 & @ERRS_BASIC as im2_has_basic_error
        ,im1.record_status_1
        ,@ERR_LOC_NOMAST as error_bit
        ,im1.record_status_1 ^ @ERR_LOC_NOMAST as val_after_turn_err_off
        */
update 	im1
set	im1.record_status_1 = im1.record_status_1 ^ @ERR_LOC_NOMAST	-- turn off the bit that indicates an error
from 	iminvmast_loc_vw	im1
	,iminvmast_vw	im2
	,#t1
where	im1.record_id_num = #t1.record_id_num
and 	im1.part_no = im2.part_no
and 	im2.company_code = @w_cc
and	(im2.record_type & @RECTYPE_INVMST_BASE) > 0		-- base records
and 	(im2.record_status_1 & @ERRS_BASIC) = 0

/* now check against the current company database */

update  im1
set     im1.record_status_1 = im1.record_status_1 ^ @ERR_LOC_NOMAST
from    iminvmast_loc_vw    im1
        ,inv_master         im2
	,#t1
where   im1.record_id_num = #t1.record_id_num
and 	im1.part_no = im2.part_no
and     (im1.record_status_1 & @ERR_LOC_NOMAST) > 0         -- if it has been validated already then this will return 0
---and     (im1.record_type & @RECTYPE_INVMST_BASE) > 0        -- makes sure that the bit is on
and     im2.void = 'N'




/*********************************************************/
-- validate pricing records
/********************************************************/
update  imp
set     imp.record_status_2 = imp.record_status_2 ^ @ERR_PRIC_UOM
from    iminvmast_pric_vw imp
        ,uom_list u
	,#t1
where   imp.record_id_num = #t1.record_id_num
and 	imp.uom = u.uom

update  imp
set     imp.record_status_2 = imp.record_status_2 ^ @ERR_PRIC_NOLOC
from    iminvmast_pric_vw imp,
        inv_master im,
	#t1
where   imp.record_id_num = #t1.record_id_num
and 	imp.part_no = im.part_no

update  imp
set     imp.record_status_2 = imp.record_status_2 ^ @ERR_PRIC_NOLOC
--select  imp.*
from    iminvmast_pric_vw imp,
        iminvmast_mstr_vw imm,
	#t1
where   imp.record_id_num = #t1.record_id_num
and 	(imp.record_status_2 & @ERR_PRIC_NOLOC) > 0
and     (imm.record_status_1 & @ERRS_BASIC) = 0
and     imp.part_no = imm.part_no
and 	imm.company_code = @w_cc

/*********************************************************/
-- validate build plan records
/********************************************************/

update 	iminvmast_bom_vw
set 	record_status_1 = record_status_1 ^ @ERR_ACTIVE_FLAG
from 	iminvmast_bom_vw,
	#t1
where	bom_active_flag in ('A','B','U')
and 	iminvmast_bom_vw.record_id_num = #t1.record_id_num

update 	iminvmast_bom_vw
set 	record_status_1 = record_status_1 ^ @ERR_BPLOC
from 	iminvmast_bom_vw,
	locations,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_status_1 & @ERR_BPLOC) > 0
and 	(	iminvmast_bom_vw.location = locations.location
	or	iminvmast_bom_vw.location = 'ALL'
	)

update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INVLDPART
from 	iminvmast_bom_vw
	,inv_master
where 	iminvmast_bom_vw.company_code = @w_cc
and 	(iminvmast_bom_vw.record_status_1 & @ERR_INVLDPART) > 0
and	iminvmast_bom_vw.part_no = inv_master.part_no
and 	iminvmast_bom_vw.process_status = 0


update 	iminvmast_bom_vw
set	iminvmast_bom_vw.record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INVLDPART
from 	iminvmast_bom_vw,
	iminvmast_mstr_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and	iminvmast_bom_vw.part_no = iminvmast_mstr_vw.part_no
and 	(iminvmast_bom_vw.record_status_1 & @ERR_INVLDPART) > 0
and 	iminvmast_mstr_vw.company_code = @w_cc
and 	iminvmast_mstr_vw.record_status_1 = 0
and 	iminvmast_mstr_vw.record_status_2 = 0
and 	iminvmast_mstr_vw.process_status = 0


update 	iminvmast_bom_vw
set	record_status_1 = record_status_1 ^ @ERR_CONSTRAIN
from 	iminvmast_bom_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	bom_constrain in ('Y','N')

update 	iminvmast_bom_vw
set 	record_status_1 = record_status_1 ^ @ERR_FIXED
from 	iminvmast_bom_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	bom_fixed in ('Y','N')

update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_INVLD_BPPART
from 	iminvmast_bom_vw
	,inv_master
	,#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_status_2 & @ERR_INVLD_BPPART) > 0
and	iminvmast_bom_vw.bom_part_no = inv_master.part_no


update 	iminvmast_bom_vw
set	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_INVLD_BPPART
from 	iminvmast_bom_vw,
	iminvmast_mstr_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and	iminvmast_bom_vw.bom_part_no = iminvmast_mstr_vw.part_no
and 	(iminvmast_bom_vw.record_status_2 & @ERR_INVLD_BPPART) > 0
and 	iminvmast_mstr_vw.company_code = @w_cc
and 	iminvmast_mstr_vw.record_status_1 = 0
and 	iminvmast_mstr_vw.record_status_2 = 0
and 	iminvmast_mstr_vw.process_status = 0

-- if the part is valid, then I need to check that the unit of measure is valid for that item.
update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_BP_UOM
from 	iminvmast_bom_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_status_2 & @ERR_INVLD_BPPART) > 0 --bom_part_no is not good turn the error off
and 	(iminvmast_bom_vw.record_status_2 & @ERR_BP_UOM) > 0


update 	iminvmast_bom_vw
set	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_BP_UOM
from 	iminvmast_bom_vw,
	inv_master,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_status_2 & @ERR_BP_UOM) > 0
and 	iminvmast_bom_vw.bom_part_no = inv_master.part_no
and 	iminvmast_bom_vw.uom = inv_master.uom


update 	iminvmast_bom_vw
set	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 ^ @ERR_BP_UOM
from 	iminvmast_bom_vw,
	iminvmast_mstr_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_status_2 & @ERR_BP_UOM) > 0
and 	iminvmast_bom_vw.bom_part_no = iminvmast_mstr_vw.part_no
and 	iminvmast_bom_vw.uom = iminvmast_mstr_vw.uom
and 	iminvmast_mstr_vw.record_status_1 = 0
and 	iminvmast_mstr_vw.record_status_2 = 0
and 	iminvmast_mstr_vw.process_status = 0

update 	iminvmast_bom_vw
set	iminvmast_bom_vw.record_status_1 = iminvmast_bom_vw.record_status_1 ^ @ERR_INCOMPTYPES
from 	iminvmast_bom_vw,
	#t1
where	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(iminvmast_bom_vw.record_type ^ @RECTYPE_INVBOM) = 0

update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 | @ERR_BP_SEQ
from 	iminvmast_bom_vw,
	#t1
where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
and 	(	iminvmast_bom_vw.bom_seq_no is null
	or	iminvmast_bom_vw.bom_seq_no = 0
	)


update 	iminvmast_bom_vw
set 	iminvmast_bom_vw.record_status_2 = iminvmast_bom_vw.record_status_2 | @ERR_BP_SEQ
from 	iminvmast_bom_vw,
	#t1,
	(	select	iminvmast_bom_vw.part_no
		from 	iminvmast_bom_vw
			,#t1
		where 	iminvmast_bom_vw.record_id_num = #t1.record_id_num
		group by part_no, bom_seq_no
		having count(*) > 1
	) as dup_seqs
where 	iminvmast_bom_vw.part_no = dup_seqs.part_no
and 	iminvmast_bom_vw.record_id_num = #t1.record_id_num


/*********************************************************/
-- validate lot bin records
/********************************************************/


update 	iminvmast_lbs_vw
set 	lbs_date_tran = getdate(),
	lbs_date_expires = dateadd(yy,1,getdate())
from 	iminvmast_lbs_vw,
	#t1
where 	iminvmast_lbs_vw.record_id_num = #t1.record_id_num
and 	lbs_date_tran is null

-- make sure that the status is correct, if blank it will default to 'T' = Transfered
update 	im1
set 	im1.status = 'T'
from 	iminvmast_lbs_vw im1,
	#t1
where 	im1.record_id_num = #t1.record_id_num
and 	im1.status <> 'S'

update 	im1
set 	im1.record_status_2 = im1.record_status_2 ^ @ERR_LBS_LBTRACK
from 	iminvmast_lbs_vw im1,
	#t1
where 	im1.record_id_num = #t1.record_id_num
and 	im1.lb_tracking = 'Y'

update  im1
set     im1.record_status_2 = im1.record_status_2 ^ @ERR_LBS_NOLOC
from    iminvmast_lbs_vw im1,
        iminvmast_loc_vw im2,
	#t1
where   im1.record_id_num = #t1.record_id_num
and 	im2.company_code = @w_cc
and 	im1.part_no = im2.part_no
and     im1.location = im2.location
---and     (im1.record_status_2 & @ERR_LOC) = 0
and 	im2.record_status_1 = 0
and 	im2.record_status_2 = 0

update  im1
set     im1.record_status_2 = im1.record_status_2 ^ @ERR_LBS_NOLOC
from    iminvmast_lbs_vw im1,
        inv_list im2,
	#t1
where   im1.record_id_num = #t1.record_id_num
and 	(im1.record_status_2 & @ERR_LBS_NOLOC) > 0      -- make sure error bit is still on
and     im1.part_no = im2.part_no
and     im1.location = im2.location
and     im2.void = 'N'


update  im
set     im.record_status_2 = im.record_status_2 ^ @ERR_LBS_UOM
from    iminvmast_lbs_vw im,
        uom_list u,
	#t1
where   im.record_id_num = #t1.record_id_num
and 	(im.record_status_2 & @ERR_LBS_UOM) > 0
and     im.uom = u.uom

update  im
set     im.record_status_2 = im.record_status_2 ^ @ERR_LBS_CODE
from    iminvmast_lbs_vw im,
        issue_code ic,
	#t1
where   im.record_id_num = #t1.record_id_num
and 	im.code = ic.code

update 	im
set	im.record_status_2 = im.record_status_2 ^ @ERR_LBS_NEGQTY
from 	iminvmast_lbs_vw im,
	#t1
where 	im.record_id_num = #t1.record_id_num
and 	im.lbs_qty > 0

update 	im
set 	im.record_status_2 = im.record_status_2 ^ @ERR_LBS_NULLBINNO
from 	iminvmast_lbs_vw im,
	#t1
where 	im.record_id_num = #t1.record_id_num
and 	im.lbs_bin_no is not null
and 	im.lbs_bin_no > ''

update 	im
set 	im.record_status_2 = im.record_status_2 ^ @ERR_LBS_NULLLOTSER
from 	iminvmast_lbs_vw im,
	#t1
where 	im.record_id_num = #t1.record_id_num
and 	im.lbs_lot_ser is not null
and 	im.lbs_lot_ser > ''

update 	il
set 	il.record_status_2 = il.record_status_2 ^ @ERR_LBS_MSTRNOLBTRAK
from 	iminvmast_lbs_vw il,
	iminvmast_mstr_vw im,
	#t1
where 	il.record_id_num = #t1.record_id_num
and 	il.part_no = im.part_no
and 	im.company_code = @w_cc
and 	im.process_status = 0
and 	im.record_status_1 = 0
and 	im.record_status_2 = 0
and 	im.lb_tracking = 'Y'

update 	il
set	il.record_status_2 = il.record_status_2 ^ @ERR_LBS_MSTRNOLBTRAK
from 	iminvmast_lbs_vw il,
	inv_master im,
	#t1
where 	il.record_id_num = #t1.record_id_num
and 	(il.record_status_2 & @ERR_LBS_MSTRNOLBTRAK) > 0
and 	il.part_no = im.part_no
and 	im.lb_tracking = 'Y'


update 	il
set	il.record_status_1 = il.record_status_1 ^ @ERR_LOC_NOMAST
from 	iminvmast_lbs_vw il,
	inv_list im,
	#t1
where	il.record_id_num = #t1.record_id_num
and 	il.part_no = im.part_no
and 	il.location = im.location
and 	(il.record_status_1 & @ERR_LOC_NOMAST) > 0


update 	il
set	il.record_status_1 = il.record_status_1 ^ @ERR_LOC_NOMAST
from 	iminvmast_lbs_vw il,
	iminvmast_loc_vw im,
	#t1
where	il.record_id_num = #t1.record_id_num
and 	il.part_no = im.part_no
and 	il.location = im.location
and 	(il.record_status_1 & @ERR_LOC_NOMAST) > 0
and 	im.company_code = @w_cc
and 	im.process_status = 0
and 	im.record_status_1 = 0
and 	im.record_status_2 = 0
GO
GRANT EXECUTE ON  [dbo].[imInvVal_e7_sp] TO [public]
GO
