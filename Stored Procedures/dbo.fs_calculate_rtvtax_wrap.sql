SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [dbo].[fs_calculate_rtvtax_wrap] @rtv int, @rtntype int=0     AS

BEGIN

DECLARE @err1  int

create table #TXTaxOutput (
  control_number varchar(16) not null,
  amtTotal float,
  amtDisc float,
  amtExemption float,
  amtTax float,
  remoteDocId int
)
create index #TTO_1 on #TXTaxOutput( control_number )

create table #TXTaxLineOutput (
  control_number varchar(16) not null,
  reference_number int not null,
  t_index int,
  taxRate float,
  taxable float,
  taxCode varchar(30),
  taxability varchar(10),
  amtTax  float,
  amtDisc float,
  amtExemption float,
  taxDetailCnt int,
  amtTaxCalculated  float
)
create index #TTLO_1 on #TXTaxLineOutput( control_number, t_index)

create table #TXTaxLineDetOutput (
  control_number varchar(16) not null,
  reference_number int not null,
  t_index int,
  d_index int,
  amtBase float,
  exception smallint,
  jurisCode varchar(30),
  jurisName varchar(255),
  jurisType varchar(30),
  nonTaxable float,
  taxRate float,
  amtTax float,
  taxable float,
  taxType smallint,
  amtTaxCalculated  float
)
create index #TTLDO_1 on #TXTaxLineDetOutput( control_number, t_index, d_index)
create index #TTLDO_2 on #TXTaxLineDetOutput( control_number, jurisCode, jurisType)

CREATE TABLE #TxLineInput
(
	control_number		varchar(16),
	reference_number	int,
	tax_code			varchar(8),
	quantity			float,
	extended_price		float,
	discount_amount		float,
	tax_type			smallint,
	currency_code		varchar(8)
)
create index #TLI_1 on #TxLineInput( control_number, reference_number)

CREATE TABLE #TxInfo
(	control_number		varchar(16),	sequence_id		int,		tax_type_code		varchar(8),
	amt_taxable		float,		amt_gross		float,		amt_tax			float,
	amt_final_tax		float,		currency_code		varchar(8),	tax_included_flag	smallint	)
create index #TI_1 on #TxInfo( control_number, sequence_id)

CREATE TABLE #txconnhdrinput (
doccode	varchar(16),
doctype	int,
trx_type smallint,
companycode 	varchar(25),
docdate 	datetime,
exemptionno 	varchar(20),
salespersoncode 	varchar(20),
discount 	float,
purchaseorderno 	varchar(20),
customercode 	varchar(20),
customerusagetype 	varchar(20) ,
detaillevel 	varchar(20) ,
referencecode 	varchar(20) ,
oriaddressline1	varchar(40),
oriaddressline2	varchar(40) ,
oriaddressline3	varchar(40) ,
oricity	varchar(40) ,
oriregion	varchar(40) ,
oripostalcode	varchar(40) ,
oricountry	varchar(40) ,
destaddressline1	varchar(40),
destaddressline2	varchar(40) ,
destaddressline3	varchar(40) ,
destcity	varchar(40) ,
destregion	varchar(40) ,
destpostalcode	varchar(40) ,
destcountry	varchar(40) ,
currCode varchar(8),
currRate decimal(20,8),
currRateDate datetime null,
locCode varchar(20) null,
paymentDt datetime null,
taxOverrideReason varchar(20) null,
taxOverrideAmt decimal(20,8) null,
taxOverrideDate datetime null,
taxOverrideType int null,
commitInd int null
)
create index TCHI_1 on #txconnhdrinput( doctype, doccode)
create index TCHI_2 on #txconnhdrinput( doccode)

CREATE TABLE #txconnlineinput (
doccode varchar(16),
no	varchar(20),
oriaddressline1	varchar(40),
oriaddressline2	varchar(40) ,
oriaddressline3	varchar(40) ,
oricity	varchar(40) ,
oriregion	varchar(40) ,
oripostalcode	varchar(40) ,
oricountry	varchar(40) ,
destaddressline1	varchar(40),
destaddressline2	varchar(40) ,
destaddressline3	varchar(40) ,
destcity	varchar(40) ,
destregion	varchar(40) ,
destpostalcode	varchar(40) ,
destcountry	varchar(40) ,
qty	float ,
amount	float,
discounted	smallint, 
exemptionno	varchar(20),
itemcode	varchar(40) ,
ref1	varchar(20) ,
ref2	varchar(20) ,
revacct	varchar(20) ,
taxcode	varchar(8) ,
customerUsageType varchar(20) null,
description varchar(255) null,
taxIncluded int null,
taxOverrideReason varchar(20) null,
taxOverrideTaxAmount decimal(20,8) null,
taxOverrideTaxDate datetime null,
taxOverrideType int null
)
create index TCLI_1 on #txconnlineinput( doccode, no)

create table #TXLineInput_ex(
  row_id int identity,
  control_number varchar(16) not null,
  reference_number int not null,
  trx_type int not null default(0),
  currency_code	varchar(8),
  curr_precision int,
  amt_tax decimal(20,8) default(0),
  amt_final_tax decimal(20,8) default(0),
  tax_code varchar(8),
  freight decimal(20,8) default(0),
  qty decimal(20,8) default(1),
  unit_price decimal(20,8) default(0),
  extended_price decimal(20,8) default(0),
  amt_discount decimal(20,8) default(0),
  err_no int default(0),
  action_flag int default(0),
  seqid int,
  calc_tax decimal(20,8) default(0),
  vat_prc decimal(20,8) default(0),
  amt_nonrecoverable_tax decimal(20,8) default(0),
  amtTaxCalculated decimal(20,8) default(0))
create index TXti1 on #TXLineInput_ex(control_number,row_id)
create index TXti2 on #TXLineInput_ex(control_number, reference_number)
create index TXti3 on #TXLineInput_ex(row_id)

create table #TXtaxtype (
  row_id int identity,
  ttr_row int,
  tax_type varchar(8),
  ext_amt decimal(20,8),
  amt_gross decimal(20,8),
  amt_taxable decimal(20,8),
  amt_tax decimal(20,8),
  amt_final_tax decimal(20,8),
  amt_tax_included decimal(20,8),
  save_flag int,
  tax_rate decimal(20,8),
  prc_flag int,
  prc_type int,
  cents_code_flag int,
  cents_code varchar(8),
  cents_cnt int,
  tax_based_type int,
  tax_included_flag int,
  modify_base_prc decimal(20,8),
  base_range_flag int,
  base_range_type int,
  base_taxed_type int,
  min_base_amt decimal(20,8),
  max_base_amt decimal(20,8),
  tax_range_flag int,
  tax_range_type int,
  min_tax_amt decimal(20,8),
  max_tax_amt decimal(20,8),
  recoverable_flag int,
  dtl_incl_ind int NULL)
create index TXtt1 on #TXtaxtype(row_id)
create index TXtt2 on #TXtaxtype(ttr_row)

create table #TXtaxtyperec (
  row_id int identity,
  tc_row int,
  tax_code varchar(8),
  seq_id int,
  base_id int,
  cur_amt decimal(20,8),
  old_tax decimal(20,8),
  tax_type varchar(8))
create index TXttr1 on #TXtaxtyperec(row_id)
create index TXttr2 on #TXtaxtyperec(tc_row)
create index TXttr3 on #TXtaxtyperec(tax_code, tc_row, seq_id)

create table #TXtaxcode (
  row_id int identity,
  ti_row int,
  control_number varchar(16),
  tax_code varchar(8),
  amt_tax decimal(20,8),
  tax_included_flag int,
  tax_type_cnt int,
  tot_extended_amt decimal(20,8))
create index TXtc1 on #TXtaxcode(row_id)
create index TXtc2 on #TXtaxcode(control_number, tax_code)

create table #TXcents (
  row_id int identity,
  cents_code varchar(8),
  to_cent decimal(20,8),
  tax_cents decimal(20,8))

create index c1 on #TXcents(cents_code,row_id)

exec   dbo.fs_calculate_rtvtax @rtv, @rtntype, @err1 OUT

      if @rtntype  = 0
		begin
		  exec adm_get_tax_detail @rtv, 0, @err1
		end
        else
		return @err1

END
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_rtvtax_wrap] TO [public]
GO
