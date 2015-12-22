SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                






 

CREATE PROCEDURE [dbo].[IntegrateSO_upd] (@InputXml NTEXT, @debug_level int = 0)
AS

DECLARE @iError 		NUMERIC
DECLARE @errors 		VARCHAR(8000)
DECLARE @result			INT
DECLARE @hDoc 			INTEGER
DECLARE @key_table 		VARCHAR(30)
DECLARE @key_table2		VARCHAR(30)
DECLARE @source			INTEGER
DECLARE @ErrorInd		INTEGER


DECLARE	@TEMPrequireddate 	DATETIME 	
DECLARE	@TEMPsonumber 		VARCHAR(18) 	
DECLARE	@TEMPusrfirstname 	VARCHAR(18) 	
DECLARE	@TEMPusrlastname 	VARCHAR(18) 	
DECLARE	@TEMPshipto 		VARCHAR(50) 
DECLARE	@TEMPshiptoaddress1 	VARCHAR(50) 	
DECLARE	@TEMPshiptoaddress2 	VARCHAR(50) 	
DECLARE	@TEMPshiptoaddress3 	VARCHAR(50)	
DECLARE	@TEMPshiptoaddress4 	VARCHAR(50) 	
DECLARE	@TEMPshiptoaddress5 	VARCHAR(50) 	
DECLARE	@TEMPshiptoaddress6 	VARCHAR(50) 	
DECLARE	@TEMPshiptocity 	VARCHAR(40) 	
DECLARE	@TEMPshiptostate 	VARCHAR(50) 	
DECLARE	@TEMPshiptozip 		CHAR(10) 	
DECLARE	@TEMPshiptocountry 	VARCHAR(20) 	
DECLARE	@TEMPordcountry		VARCHAR(20)	
DECLARE	@TEMPtransstatus 	VARCHAR(20) 	
DECLARE	@TEMPsoldto		VARCHAR(10)
DECLARE	@TEMPsoldtoaddress1 	VARCHAR(50) 	
DECLARE	@TEMPsoldtoaddress2 	VARCHAR(50) 	
DECLARE	@TEMPsoldtoaddress3 	VARCHAR(50) 	
DECLARE	@TEMPsoldtoaddress4 	VARCHAR(50) 	
DECLARE	@TEMPsoldtoaddress5 	VARCHAR(50) 	
DECLARE	@TEMPsoldtoaddress6 	VARCHAR(50)	
DECLARE	@TEMPcarrier		VARCHAR(20)
DECLARE	@TEMPfob 		VARCHAR(8)
DECLARE	@TEMPterms		VARCHAR(8)
DECLARE	@TEMPtax		VARCHAR(8)
DECLARE	@TEMPpostingcode	VARCHAR(8)	
DECLARE	@TEMPcurrency		VARCHAR(8)	
DECLARE	@TEMPsalesperson	VARCHAR(8)	
DECLARE	@TEMPuserstatus		VARCHAR(8)	
DECLARE	@TEMPblanket		CHAR(1)
DECLARE	@TEMPblanketfrom	DATETIME	
DECLARE	@TEMPblanketto		DATETIME	
DECLARE	@TEMPblanketamount	FLOAT	
DECLARE	@TEMPlocation		VARCHAR(10)	
DECLARE	@TEMPbackorder		CHAR(1)	
DECLARE	@TEMPcategory		VARCHAR(10)	
DECLARE	@TEMPsopriority		CHAR(1)	
DECLARE	@TEMPdisc		VARCHAR(13)
DECLARE	@TEMPdeliverydt		DATETIME	
DECLARE	@TEMPshipdt		DATETIME
DECLARE	@TEMPcanceldt		DATETIME	
DECLARE	@TEMPmessageid 		VARCHAR(50)	
DECLARE	@TEMPnote		VARCHAR(255)
DECLARE	@TEMPhold		VARCHAR(10)
DECLARE	@TEMPshipinst		VARCHAR(255)	
DECLARE	@TEMPfowarder		VARCHAR(8)	
DECLARE	@TEMPfreight		VARCHAR(13)
DECLARE	@TEMPfreightto		VARCHAR(8)	
DECLARE	@TEMPfreighttype	VARCHAR(8)	
DECLARE	@TEMPuserdeffld1	VARCHAR(255)	
DECLARE	@TEMPuserdeffld2	VARCHAR(255)	
DECLARE	@TEMPuserdeffld3	VARCHAR(255)	
DECLARE	@TEMPuserdeffld4	VARCHAR(255)	
DECLARE	@TEMPuserdeffld5	FLOAT	
DECLARE	@TEMPuserdeffld6	FLOAT	
DECLARE	@TEMPuserdeffld7	FLOAT	
DECLARE	@TEMPuserdeffld8	FLOAT	
DECLARE	@TEMPuserdeffld9	INTEGER	
DECLARE	@TEMPuserdeffld10	INTEGER	
DECLARE	@TEMPuserdeffld11	INTEGER	
DECLARE	@TEMPuserdeffld12	INTEGER	
DECLARE	@TEMPpoaction		SMALLINT	


DECLARE	@TEMPsonumberdet 	VARCHAR(18) 
DECLARE	@TEMPlinenumber 	INTEGER
DECLARE	@TEMPpartno 		VARCHAR(20) 
DECLARE	@TEMPtype		CHAR(1)
DECLARE	@TEMPquantity 		NUMERIC 
DECLARE	@TEMPunitofmeasure 	VARCHAR(20) 
DECLARE	@TEMPloc	 	VARCHAR(10)
DECLARE	@TEMPitemdescription	VARCHAR(255) 
DECLARE	@TEMPdetailcomment 	VARCHAR(255) 
DECLARE	@TEMPcompany 		VARCHAR(180)
DECLARE	@TEMPaccount 		VARCHAR(180) 
DECLARE	@TEMPcomm		VARCHAR(13) --dec.   sp_help ord_list
DECLARE	@TEMPtaxcode		VARCHAR(10)
DECLARE	@TEMPcustomer		VARCHAR(20)
DECLARE	@TEMPusercount		INT
DECLARE	@TEMPcreatepo		SMALLINT
DECLARE	@TEMPbackorderdet	CHAR(1)
DECLARE	@TEMPreference 		VARCHAR(180)
DECLARE	@TEMPlogin 		VARCHAR(30) 
DECLARE	@TEMPsoaction 		INT 
DECLARE	@TEMPprice 		DECIMAL(20, 8) 
DECLARE	@TEMPfreightdet 	DECIMAL(20,8)
DECLARE	@TEMPwhoentered		VARCHAR(20)	
DECLARE @TEMPitemnote		VARCHAR(25)
DECLARE @so_no			VARCHAR(18)




DECLARE @TEMPvoid		CHAR(1)

DECLARE	@TEMPattention		VARCHAR(40)	
DECLARE @TEMPphone		VARCHAR(20)
DECLARE @TEMPconsolidation	SMALLINT

DECLARE @count 			INTEGER
DECLARE @change_flag 		VARCHAR(30)


DECLARE	@TEMPshipto_det		VARCHAR(50)
DECLARE	@TEMPfob_det		VARCHAR(10)
DECLARE	@TEMProuting		VARCHAR(20)
DECLARE	@TEMPforwarder		VARCHAR(10)
DECLARE	@TEMPshiptoregion	VARCHAR(10)
DECLARE	@TEMPdestzone		VARCHAR(8)


DECLARE	@TEMPshipto_n		VARCHAR(50)
DECLARE	@TEMPfob_n		VARCHAR(10)
DECLARE	@TEMProuting_n		VARCHAR(20)
DECLARE	@TEMPforwarder_n	VARCHAR(10)
DECLARE	@TEMPshiptoregion_n	VARCHAR(10)
DECLARE	@TEMPdestzone_n		VARCHAR(8)

DECLARE @TEMPext		INTEGER
DECLARE @TEMPext_d		INTEGER

DECLARE @today			INTEGER



--DECLARE @TEMPcustomerh VARCHAR(20)


DECLARE @err_section 		CHAR(30)

DECLARE @no_upd_flag 		INT

SET @no_upd_flag = 0

SET @err_section = 'IntegrateSO_upd.sp'
IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/IntegrateSO_upd.sp' + ', line ' + STR( 124, 5 ) + ' -- ENTRY: '
CREATE TABLE #ewerror
(
	module_id smallint,
	err_code  int,
	info char(255),
	source char (20),
	sequence_id int
)


CREATE TABLE #arcrchk
( 
  customer_code		varchar(8),
  check_credit_limit		smallint,
  credit_limit		float,
  limit_by_home		smallint
)
CREATE UNIQUE INDEX #arcrchk_ind_0 ON #arcrchk (customer_code)


CREATE TABLE #TEMPSO (
	key_table 		INTEGER IDENTITY(1,1), 
	RequiredDate 		DATETIME, 
	SONumber 		VARCHAR(18), 
	UsrFirstName 		VARCHAR(18), 
	UsrLastName 		VARCHAR(18), 
	ShipTo 			VARCHAR(50), 
	ShipToAddress1 		VARCHAR(50), 
	ShipToAddress2 		VARCHAR(50), 
	ShipToAddress3 		VARCHAR(50),
	ShipToAddress4 		VARCHAR(50), 
	ShipToAddress5 		VARCHAR(50), 
	ShipToAddress6 		VARCHAR(50), 
	ShipToCity 		VARCHAR(40), 
	ShipToState 		VARCHAR(50), 
	ShipToZip 		CHAR(10), 
--	ShipToCountry 		VARCHAR(20), 
	OrdCountry		VARCHAR(20),
	TransStatus 		VARCHAR(20), 
	SoldTo			VARCHAR(10),
	SoldToAddress1 		VARCHAR(50), 
	SoldToAddress2 		VARCHAR(50), 
	SoldToAddress3 		VARCHAR(50), 
	SoldToAddress4 		VARCHAR(50), 
	SoldToAddress5 		VARCHAR(50), 
	SoldToAddress6 		VARCHAR(50),
	Carrier			VARCHAR(20),
	Fob 			VARCHAR(8),
	Terms			VARCHAR(8),
	Tax			VARCHAR(8),
	PostingCode		VARCHAR(8),
	Currency		VARCHAR(8),
	SalesPerson		VARCHAR(8),
	UserStatus		VARCHAR(8),
	Blanket			CHAR(1),
	BlanketFrom		DATETIME,
	BlanketTo		DATETIME,
	BlanketAmount		FLOAT,
	Location		VARCHAR(10),
	BackOrder		CHAR(1),
	Category		VARCHAR(10),
	SOPriority		CHAR(1),
	Disc			VARCHAR(13),
	DeliveryDt		DATETIME,
	ShipDt			DATETIME,
	CancelDt		DATETIME,
	MessageID 		VARCHAR(50),
	Note	 		VARCHAR(255),
	Hold			VARCHAR(10),
	ShipInst		VARCHAR(255),
	Fowarder		VARCHAR(8),
	Freight			VARCHAR(13),
	FreightTo		VARCHAR(8),
	FreightType		VARCHAR(8),
	Consolidate		SMALLINT,
	UserDefFld1		VARCHAR(255),
	UserDefFld2		VARCHAR(255),
	UserDefFld3		VARCHAR(255),
	UserDefFld4		VARCHAR(255),
	UserDefFld5		FLOAT,
	UserDefFld6		FLOAT,
	UserDefFld7		FLOAT,
	UserDefFld8		FLOAT,
	UserDefFld9		INTEGER,
	UserDefFld10		INTEGER,
	UserDefFld11		INTEGER,
	UserDefFld12		INTEGER,
	Poaction		SMALLINT,
	Attention		VARCHAR(40),
	Phone			VARCHAR(20),
	Void			CHAR(1),
	NewSO			VARCHAR(18),

	Ext			INTEGER,

	Source			INTEGER	
)
--	
--	AutoShip
--	FastSO
--	Multiple ship to.
--	Consolidate Invoice.   sp_help orders
--	Freight			VARCHAR(13),


CREATE UNIQUE INDEX hist_index1
ON #TEMPSO (key_table)


CREATE TABLE #TEMPSOD (
	key_table 		INTEGER IDENTITY(1,1), 
	SONumber 		VARCHAR(18), 
	LineNumber 		INTEGER,
	PartNo 			VARCHAR(20), 
	Type			CHAR(1),
	Quantity 		NUMERIC, 
	UnitOfMeasure 		VARCHAR(20), 
	Loc 			VARCHAR(50), 
	ItemDescription		VARCHAR(255), 
	DetailComment 		VARCHAR(255), 
	Company 		VARCHAR(180),	
	Account 		VARCHAR(180), 	
	Comm			VARCHAR(13), 
	TaxCode			VARCHAR(10),
	Customer		VARCHAR(20),
	UserCount		INT,
	CreatePO		SMALLINT,
	BackOrder		CHAR(1),	
	Reference 		VARCHAR(180),
	Login 			VARCHAR(30), 
	SOAction 		INT, 
	Price 			DECIMAL(20, 8), 
	Freight 		DECIMAL(20,8),
	Poaction		SMALLINT,

	ShipTo 			VARCHAR(50),
	Fob			VARCHAR(10),
	Routing			VARCHAR(20),
	Forwarder		VARCHAR(10),
	ShipToRegion		VARCHAR(10),
	DestZone		VARCHAR(8),

	Ext			INTEGER,	

	ItemNote		VARCHAR(255)
)

CREATE UNIQUE INDEX hist_det_index1
ON #TEMPSOD (key_table)


CREATE TABLE #TEMPSOD_NEWDET
(
	key_table 		INTEGER IDENTITY(1,1), 
	SONumber 		VARCHAR(18), 
	LineNumber 		INTEGER,
	PartNo 			VARCHAR(20), 
	Type			CHAR(1),
	Quantity 		NUMERIC, 
	UnitOfMeasure 		VARCHAR(20), 
	Loc 			VARCHAR(50), 
	ItemDescription		VARCHAR(255), 
	DetailComment 		VARCHAR(255), 
	Company 		VARCHAR(180),	
	Account 		VARCHAR(180), 	
	Comm			VARCHAR(13), 
	TaxCode			VARCHAR(10),
	Customer		VARCHAR(20),
	UserCount		INT,
	CreatePO		SMALLINT,
	BackOrder		CHAR(1),	
	Reference 		VARCHAR(180),
	Login 			VARCHAR(30), 
	SOAction 		INT, 
	Price 			DECIMAL(20, 8), 
	Freight 		DECIMAL(20,8),
	Poaction		SMALLINT,

	ShipTo 			VARCHAR(50),
	Fob			VARCHAR(10),
	Routing			VARCHAR(20),
	Forwarder		VARCHAR(10),
	ShipToRegion		VARCHAR(10),
	DestZone		VARCHAR(8),

	Ext			INTEGER,

	ItemNote		VARCHAR(255)
)



CREATE TABLE #TEMPSOPAY (
	key_table 		INTEGER IDENTITY(1,1), 
	order_no		INT,
	trx_desc		VARCHAR(40),
	date_doc		DATETIME,
	payment_code		VARCHAR(8),
	amt_payment		DECIMAL(13),
	prompt1_inp		VARCHAR(30),
	prompt2_inp		VARCHAR(30),
	prompt3_inp		VARCHAR(30),
	prompt4_inp		VARCHAR(30),
	amt_disc_taken		DECIMAL(13),
	cash_acct_code		VARCHAR(32),
	doc_ctrl_num		VARCHAR(16)
)
CREATE UNIQUE INDEX hist_pay_index1
ON #TEMPSOPAY (key_table)


CREATE TABLE #TEMPSOCO (
	key_table 		INTEGER IDENTITY(1,1), 
	order_no		INT,
	display_line		INT,
	salesperson		VARCHAR(10),
	sales_comm		DECIMAL(13),
	percent_flag		SMALLINT,
	exclusive_flag		SMALLINT,
	split_flag		SMALLINT,	
	note			VARCHAR(255)

)
CREATE UNIQUE INDEX hist_co_index1
ON #TEMPSOCO (key_table)


CREATE TABLE #TEMPSORE(
	key_table		INTEGER IDENTITY(1,1),
	ext			INT,
	ord_detail_line		INT,
	order_no		INT,
	sch_ship_date		DATETIME,
	ordered			INT	
)
CREATE UNIQUE INDEX hist_re_index1
ON #TEMPSORE (key_table)















SET @iError = 0 
SET @errors = ''


IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/IntegrateSO_upd.sp' + ', line ' + STR( 124, 5 ) + ' -- Fill temp tables: '

EXEC @iError = sp_xml_preparedocument @hDoc OUTPUT, @InputXml


INSERT INTO #TEMPSO 
	SELECT 		[RequiredDate],
			[SONumber],
			[UsrFirstName],
			[UsrLastName],
			[ShipTo],
			[ShipToAddress1],
			[ShipToAddress2],
			[ShipToAddress3],
			[ShipToAddress4],
			[ShipToAddress5],
			[ShipToAddress6],
			[ShipToCity],
			[ShipToState],
			[ShipToZip],
			[OrdCountry],
			[TransStatus],
			[SoldTo],
			[SoldToAddress1],
			[SoldToAddress2],
			[SoldToAddress3],
			[SoldToAddress4],
			[SoldToAddress5],
			[SoldToAddress6],
			[Carrier],
			[Fob],
			[Terms],
			[Tax],
			[PostingCode],
			[Currency],
			[SalesPerson],
			[UserStatus],
			[Blanket],
			[BlanketFrom],
			[BlanketTo],
			[BlanketAmount],
			[Location],
			[BackOrder],
			[Category],
			[SOPriority],
			[Disc],
			[DeliveryDt],
			[ShipDt],
			[CancelDt],
			[MessageID],
			[Note],
			[Hold],
			[ShipInst],
			[Fowarder],
			[Freight],
			[FreightTo],
			[FreightType],
			[Consolidate],
			[UserDefFld1],
			[UserDefFld2],
			[UserDefFld3],  
			[UserDefFld4],
			[UserDefFld5],
			[UserDefFld6],
			[UserDefFld7],
			[UserDefFld8],
			[UserDefFld9],
			[UserDefFld10],
			[UserDefFld11],
			[UserDefFld12],
			[Poaction],
			[Attention],
			[Phone],
			[Void],
			[NewSO],

			[Ext],

			ISNULL([Source], 0)
	FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrderUpd/SalesOrder/Header', 2)
	WITH
	(
	key_table 		INTEGER , 
	RequiredDate 		DATETIME	'req_ship_date', 
	SONumber 		VARCHAR(18)	'order_no', 
	UsrFirstName 		VARCHAR(18), 
	UsrLastName 		VARCHAR(18), 
	ShipTo 			VARCHAR(50)	'ship_to', 
	ShipToAddress1 		VARCHAR(50)	'ship_to_add_1', 
	ShipToAddress2 		VARCHAR(50)	'ship_to_add_2', 
	ShipToAddress3 		VARCHAR(50)	'ship_to_add_3',
	ShipToAddress4 		VARCHAR(50)	'ship_to_add_4', 
	ShipToAddress5 		VARCHAR(50)	'ship_to_add_5', 
	ShipToAddress6 		VARCHAR(50), 
	ShipToCity 		VARCHAR(40)	'ship_to_city', 
	ShipToState 		VARCHAR(50)	'ship_to_state', 
	ShipToZip 		CHAR(10)	'ship_to_zip', 
	OrdCountry		VARCHAR(20)	'ship_to_country',
	TransStatus 		VARCHAR(20), 
	SoldTo			VARCHAR(10)	'cust_code',
	SoldToAddress1 		VARCHAR(50)	'sold_to_addr1', 
	SoldToAddress2 		VARCHAR(50)	'sold_to_addr2', 
	SoldToAddress3 		VARCHAR(50)	'sold_to_addr3', 
	SoldToAddress4 		VARCHAR(50)	'sold_to_addr4', 
	SoldToAddress5 		VARCHAR(50)	'sold_to_addr5', 
	SoldToAddress6 		VARCHAR(50)	'sold_to_addr6',
	Carrier			VARCHAR(20)	'routing',
	Fob 			VARCHAR(8)	'fob',
	Terms			VARCHAR(8)	'terms',
	Tax			VARCHAR(8)	'tax_id',
	PostingCode		VARCHAR(8)	'posting_code',	
	Currency		VARCHAR(8)	'curr_key',
	SalesPerson		VARCHAR(8)	'salesperson',
	UserStatus		VARCHAR(8)	'user_code',
	Blanket			CHAR(1)		'blanket',
	BlanketFrom		DATETIME	'from_date',
	BlanketTo		DATETIME	'to_date',
	BlanketAmount		FLOAT		'blanket_amt',
	Location		VARCHAR(10)	'location',
	BackOrder		CHAR(1)		'back_ord_flag',
	Category		VARCHAR(10)	'user_category',
	SOPriority		CHAR(1)		'so_priority_code',
	Disc			VARCHAR(13)	'discount',
	DeliveryDt		DATETIME,
	ShipDt			DATETIME	'sch_ship_date',
	CancelDt		DATETIME	'cancel_date',
	MessageID 		VARCHAR(50),
	Note	 		VARCHAR(255)	'note',
	Hold			VARCHAR(10)	'hold_reason',
	ShipInst		VARCHAR(255)	'special_instr',
	Fowarder		VARCHAR(8)	'forwarder_key',
	Freight			VARCHAR(13)	'freight',
	FreightTo		VARCHAR(8)	'freight_to',
	FreightType		VARCHAR(8)	'freight_allow_type',
	Consolidate		SMALLINT	'consolidate_flag',
	UserDefFld1		VARCHAR(255)	'user_def_fld1',
	UserDefFld2		VARCHAR(255)	'user_def_fld2',
	UserDefFld3		VARCHAR(255)	'user_def_fld3',
	UserDefFld4		VARCHAR(255)	'user_def_fld4',
	UserDefFld5		FLOAT		'user_def_fld5',
	UserDefFld6		FLOAT		'user_def_fld6',
	UserDefFld7		FLOAT		'user_def_fld7',
	UserDefFld8		FLOAT		'user_def_fld8',
	UserDefFld9		INTEGER		'user_def_fld9',
	UserDefFld10		INTEGER		'user_def_fld10',
	UserDefFld11		INTEGER		'user_def_fld11',
	UserDefFld12		INTEGER		'user_def_fld12',
	Poaction		SMALLINT,
	Attention		VARCHAR(40)	'attention',
	Phone			VARCHAR(20)	'phone',
	Void			CHAR(1)		'void',
	NewSO			VARCHAR(18),

	Ext			INTEGER		'ext',

	Source			INTEGER		'source'
	)

SET @result = @@error
IF @result <> 0 
BEGIN 
	INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 10, @err_section + '', '', 0)	
END 

INSERT INTO #TEMPSOD 
	SELECT 		[SONumber], 
			[LineNumber],
			[PartNo], 
			[Type], 
			[Quantity], 
			[UnitOfMeasure], 
			[Loc], 
			[ItemDescription],
			[DetailComment], 
			[Company],	
			[Account], 
			[Comm],				
			[TaxCode],			
			[Customer],			
			[UserCount],			
			[CreatePO],			
			[BackOrder],			
			[Reference],  
			[Login], 
			[SOAction], 
			[Price], 
			[Freight],
			[Poaction],

			[ShipTo],
			[Fob],
			[Routing],
			[Forwarder],
			[ShipToRegion],
			[DestZone],

			[Ext],

			[ItemNote]
	FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrderUpd/SalesOrder/Header/Items/Item', 2)
	WITH
(
	key_table 		INTEGER , 
	SONumber 		VARCHAR(18)	'order_no', 
	LineNumber 		INTEGER		'line_no',
	PartNo 			VARCHAR(20)	'part_no', 
	Type			CHAR(1)		'part_type',
	Quantity 		NUMERIC		'ordered', 
	UnitOfMeasure 		VARCHAR(20)	'uom', 
	Loc 			VARCHAR(50)	'location', 
	ItemDescription		VARCHAR(255)	'description', 
	DetailComment 		VARCHAR(255), 
	Company 		VARCHAR(180),	
	Account 		VARCHAR(180)	'gl_rev_acct', 
	Comm			VARCHAR(13), 
	TaxCode			VARCHAR(10),
	Customer		VARCHAR(20),
	UserCount		INT,
	CreatePO		SMALLINT,
	BackOrder		CHAR(1),	
	Reference 		VARCHAR(180)	'reference_code',
	Login 			VARCHAR(30), 
	SOAction 		INT, 
	Price 			DECIMAL(20, 8) 	'price', 
	Freight 		DECIMAL(20,8),
	Poaction		SMALLINT,

	ShipTo			VARCHAR(50)	'ship_to',
	Fob			VARCHAR(10)	'fob',
	Routing			VARCHAR(20)	'routing',
	Forwarder		VARCHAR(10)	'forwarder_key',
	ShipToRegion		VARCHAR(10)	'ship_to_region',
	DestZone		VARCHAR(8)	'dest_zone_code',

	Ext			INTEGER		'order_ext',

	ItemNote		VARCHAR(255)	'note'
)


SET @result = @@error
IF @result <> 0 
BEGIN 
	INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 20, @err_section + '', '', 0)	
END 


INSERT INTO #TEMPSOPAY 
SELECT 
	order_no,
	trx_desc,
	date_doc,
	payment_code,
	amt_payment,
	prompt1_inp,
	prompt2_inp,
	prompt3_inp,
	prompt4_inp,	
	amt_disc_taken,
	cash_acct_code,
	doc_ctrl_num
FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrderUpd/SalesOrder/Header/Payment', 2)
WITH #TEMPSOPAY


SET @result = @@error
IF @result <> 0 
BEGIN 
	INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 50, @err_section + '', '', 0)	
END 


INSERT INTO #TEMPSOCO 
SELECT DISTINCT
	order_no,
	display_line,
	salesperson,
	sales_comm,
	percent_flag,
	exclusive_flag,
	split_flag,
	note
FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrderUpd/SalesOrder/Header/Comissions/Comission', 2)
WITH #TEMPSOCO


SET @result = @@error
IF @result <> 0 
BEGIN 
	INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 60, @err_section + '', '', 0)	
END 



INSERT INTO #TEMPSORE
SELECT DISTINCT
	ext,
	ord_detail_line,
	order_no,
	sch_ship_date,
	ordered
FROM OPENXML (@hDoc, '/BackOfficeIV.SalesOrderUpd/SalesOrder/Header/Releases/Release', 2)
WITH #TEMPSORE


SET @result = @@error
IF @result <> 0 
BEGIN 
	INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 70, @err_section + '', '', 0)	
END 











if (((SELECT COUNT(key_table) FROM #TEMPSO WHERE SONumber IS NULL)= (SELECT COUNT(key_table) FROM #TEMPSO)))
begin

	if ((SELECT COUNT(1) FROM #TEMPSOD)= 0) 
	begin
		return ''
	end
end
	else 
	begin  
		DELETE  FROM #TEMPSO 
		WHERE SONumber is NULL
		AND 	RequiredDate 	IS NULL
		AND	SONumber 	IS NULL
		AND	ShipTo 		IS NULL
		AND	ShipToAddress1 	IS NULL
		AND	ShipToAddress2 	IS NULL
		AND	ShipToAddress3 	IS NULL
		AND	ShipToAddress4 	IS NULL
		AND	ShipToAddress5 	IS NULL
		AND	ShipToCity 	IS NULL
		AND	ShipToState 	IS NULL
		AND	ShipToZip 	IS NULL
		AND	OrdCountry	IS NULL
		AND	SoldTo		IS NULL
		AND	SoldToAddress1 	IS NULL
		AND	SoldToAddress2 	IS NULL
		AND	SoldToAddress3 	IS NULL
		AND	SoldToAddress4 	IS NULL
		AND	SoldToAddress5 	IS NULL
		AND	SoldToAddress6 	IS NULL
		AND	Carrier		IS NULL
		AND	Fob 		IS NULL
		AND	Terms		IS NULL
		AND	Tax		IS NULL
		AND	PostingCode	IS NULL
		AND	Currency	IS NULL
		AND	SalesPerson	IS NULL
		AND	UserStatus	IS NULL
		AND	Blanket		IS NULL
		AND	BlanketFrom	IS NULL
		AND	BlanketTo	IS NULL
		AND	BlanketAmount	IS NULL
		AND	Location	IS NULL
		AND	BackOrder	IS NULL
		AND	Category	IS NULL
		AND	SOPriority	IS NULL
		AND	Disc		IS NULL
		AND	ShipDt		IS NULL
		AND	CancelDt	IS NULL
		AND	Note		IS NULL
		AND	Hold		IS NULL
		AND	ShipInst	IS NULL
		AND	Fowarder	IS NULL
		AND	Freight		IS NULL
		AND	FreightTo	IS NULL
		AND	FreightType	IS NULL
		AND	Consolidate	IS NULL
		AND	UserDefFld1	IS NULL
		AND	UserDefFld2	IS NULL
		AND	UserDefFld3	IS NULL
		AND	UserDefFld4	IS NULL
		AND	UserDefFld5	IS NULL
		AND	UserDefFld6	IS NULL
		AND	UserDefFld7	IS NULL
		AND	UserDefFld8	IS NULL
		AND	UserDefFld9	IS NULL
		AND	UserDefFld10	IS NULL
		AND	UserDefFld11	IS NULL
		AND	UserDefFld12	IS NULL
		AND	Attention	IS NULL
		AND	Phone		IS NULL

		
		

		INSERT #TEMPSO
		(SONumber, Source)
		SELECT DISTINCT tempd.SONumber, 0
		FROM #TEMPSOD tempd
		LEFT JOIN #TEMPSO tempo ON tempd.SONumber = tempo.SONumber
		where tempo.SONumber IS NULL 

	end






	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT 18000, 6200, 'NULL', 'NULL', 0
	FROM  #TEMPSO temp where temp.SONumber IS NULL



	INSERT INTO #ewerror
	(module_id,err_code, info, source, sequence_id)
	SELECT 18000, 6000, 'NULL', 'NULL', 0
	FROM  #TEMPSOD temp where temp.SONumber IS NULL










	DELETE FROM #TEMPSO WHERE SONumber is NULL


	INSERT #TEMPSO
	(SONumber, Source)
	SELECT DISTINCT order_no, 0
	FROM #TEMPSOPAY tsop
	LEFT JOIN #TEMPSO tso ON tso.SONumber = tsop.order_no 
	WHERE tso.SONumber IS NULL and tsop.order_no IS NOT NULL



	INSERT #TEMPSO
	(SONumber, Source)
	SELECT DISTINCT order_no, 0
	FROM #TEMPSOCO tsop
	LEFT JOIN #TEMPSO tso ON tso.SONumber = tsop.order_no 
	WHERE tso.SONumber IS NULL and tsop.order_no IS NOT NULL



SELECT @source = max(Source) from #TEMPSO



INSERT INTO #ewerror
(module_id, err_code, info, source, sequence_id)
SELECT DISTINCT 19000, 4700, temp.SONumber, o.status, 0
FROM #TEMPSO temp
INNER JOIN orders o ON o.order_no = temp.SONumber
WHERE o.status IN ( 'V','T','S' )


if ISNULL(@source, 0) = 0
BEGIN
	IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/adm_upd_SO_validate.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '
		EXEC adm_upd_SO_validate 
	
	IF ( @debug_level > 0 ) SELECT CONVERT(char,getdate(),109) + '  ' + 'tmp/adm_upd_SO_dtl_validate.sp' + ', line ' + STR( 124, 5 ) + ' -- Validate information: '
		EXEC adm_upd_SO_dtl_validate 
END
else
BEGIN

	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5000, temp.SONumber, temp.Source, 0
	FROM #TEMPSO temp
	WHERE temp.Source > 1


	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 4600, temp.SONumber, temp.Hold, 0
	FROM #TEMPSO temp 
	LEFT JOIN adm_oehold adm ON temp.Hold = adm.hold_code
	WHERE adm.hold_code IS NULL AND temp.Hold IS NOT NULL
	AND temp.Hold <> ''	


	if exists (SELECT 1 FROM #TEMPSO temp INNER JOIN orders ord ON temp.SONumber = ord.order_no AND ISNULL(temp.Ext, 0) = ord.ext AND ISNULL(temp.Hold, ord.hold_reason) = ISNULL(ord.hold_reason, ''))
		set @no_upd_flag = 1

END


	INSERT INTO #TEMPSOD_NEWDET
	SELECT temp.SONumber, 
		temp.LineNumber,
		temp.PartNo, 
		temp.Type, 
		temp.Quantity, 
		temp.UnitOfMeasure, 
		temp.Loc, 
		temp.ItemDescription,
		temp.DetailComment, 
		temp.Company,	
		temp.Account, 
		temp.Comm,				
		temp.TaxCode,			
		temp.Customer,			
		temp.UserCount,			
		temp.CreatePO,			
		temp.BackOrder,			
		temp.Reference,  
		temp.Login, 
		temp.SOAction, 
		temp.Price, 
		temp.Freight,
		temp.Poaction,

		temp.ShipTo,
		temp.Fob,
		temp.Routing,
		temp.Forwarder,
		temp.ShipToRegion,
		temp.DestZone,

		temp.Ext,

		temp.ItemNote
	FROM #TEMPSOD temp
	LEFT JOIN ord_list pur ON temp.SONumber = pur.order_no 
		and temp.LineNumber = pur.line_no --and ISNULL(temp.PartNo, pur.part_no) = pur.part_no
	WHERE pur.order_no IS NULL 

	
	INSERT INTO #ewerror
	(module_id, err_code, info, source, sequence_id)
	SELECT DISTINCT 19000, 5300, temp.SONumber, temp.PartNo, temp.LineNumber
	FROM #TEMPSOD_NEWDET temp
	WHERE temp.SONumber IS NULL 
	AND	temp.LineNumber IS NULL
	AND	temp.PartNo IS NULL 
	AND	temp.Type IS NULL 
	AND	temp.Quantity IS NULL 
	AND	temp.UnitOfMeasure IS NULL
	AND	temp.Loc IS NULL
	AND	temp.ItemDescription IS NULL
	AND	temp.Account IS NULL
	AND	temp.Reference IS NULL
	AND	temp.Price IS NULL





	SET @ErrorInd = 0

IF EXISTS (SELECT 1 FROM #ewerror ew INNER JOIN eboerrdef so ON ew.err_code = so.e_code WHERE so.e_level = 1 and so.e_type = 'soerr')
	SET @ErrorInd = 1
ELSE
	BEGIN


		if @no_upd_flag = 0
		BEGIN

					SET @key_table = 0
					SET @iError = 0
					
					SELECT	@key_table = MIN(key_table)
					FROM	#TEMPSO
					WHERE	key_table > @key_table
					
					WHILE @key_table IS NOT NULL
					BEGIN
		
						SELECT DISTINCT
								@TEMPrequireddate 			=	TEMP.RequiredDate,	
								@TEMPsonumber 				=	TEMP.SONumber,	
								@TEMPusrfirstname 			=	TEMP.UsrFirstName,	
								@TEMPusrlastname 			=	TEMP.UsrLastName,	
								@TEMPshipto 				=	TEMP.ShipTo,	
								@TEMPshiptoaddress1 			=	TEMP.ShipToAddress1,	
								@TEMPshiptoaddress2 			=	TEMP.ShipToAddress2,	
								@TEMPshiptoaddress3 			=	TEMP.ShipToAddress3,	
								@TEMPshiptoaddress4 			=	TEMP.ShipToAddress4,	
								@TEMPshiptoaddress5 			=	TEMP.ShipToAddress5,	
								@TEMPshiptoaddress6 			=	TEMP.ShipToAddress6,	
								@TEMPshiptocity 			=	TEMP.ShipToCity,	
								@TEMPshiptostate 			=	TEMP.ShipToState,	
								@TEMPshiptozip 				=	TEMP.ShipToZip,	
								@TEMPordcountry				=	TEMP.OrdCountry,	
								@TEMPtransstatus 			=	TEMP.TransStatus,	
								@TEMPsoldto				=	TEMP.SoldTo,	
								@TEMPsoldtoaddress1 			=	TEMP.SoldToAddress1,	
								@TEMPsoldtoaddress2 			=	TEMP.SoldToAddress2,	
								@TEMPsoldtoaddress3 			=	TEMP.SoldToAddress3,	
								@TEMPsoldtoaddress4 			=	TEMP.SoldToAddress4,	
								@TEMPsoldtoaddress5 			=	TEMP.SoldToAddress5,	
								@TEMPsoldtoaddress6 			=	TEMP.SoldToAddress6,	
								@TEMPcarrier				=	TEMP.Carrier,	
								@TEMPfob 				=	TEMP.Fob,	
								@TEMPterms				=	TEMP.Terms,	
								@TEMPtax				=	TEMP.Tax,	
								@TEMPpostingcode			=	TEMP.PostingCode,	
								@TEMPcurrency				=	TEMP.Currency,	
								@TEMPsalesperson			=	TEMP.SalesPerson,	
								@TEMPuserstatus				=	TEMP.UserStatus,	
								@TEMPblanket				=	TEMP.Blanket,	
								@TEMPblanketfrom			=	TEMP.BlanketFrom,	
								@TEMPblanketto				=	TEMP.BlanketTo,	
								@TEMPblanketamount			=	TEMP.BlanketAmount,	
								@TEMPlocation				=	TEMP.Location,	
								@TEMPbackorder				=	TEMP.BackOrder,	
								@TEMPcategory				=	TEMP.Category,	
								@TEMPsopriority				=	TEMP.SOPriority,	
								@TEMPdisc				=	TEMP.Disc,	
								@TEMPdeliverydt				=	TEMP.DeliveryDt,	
								@TEMPshipdt				=	TEMP.ShipDt,	
								@TEMPcanceldt				=	TEMP.CancelDt,	
								@TEMPmessageid 				=	TEMP.MessageID,	
								@TEMPnote				=	TEMP.Note,	
								@TEMPhold				=	TEMP.Hold,	
								@TEMPshipinst				=	TEMP.ShipInst,	
								@TEMPfowarder				=	TEMP.Fowarder,	
								@TEMPfreight				=	TEMP.Freight,	
								@TEMPfreightto				=	TEMP.FreightTo,	
								@TEMPfreighttype			=	TEMP.FreightType,
								@TEMPconsolidation			=	TEMP.Consolidate,	
								@TEMPuserdeffld1			=	TEMP.UserDefFld1,	
								@TEMPuserdeffld2			=	TEMP.UserDefFld2,	
								@TEMPuserdeffld3			=	TEMP.UserDefFld3,  	
								@TEMPuserdeffld4			=	TEMP.UserDefFld4,	
								@TEMPuserdeffld5			=	TEMP.UserDefFld5,	
								@TEMPuserdeffld6			=	TEMP.UserDefFld6,	
								@TEMPuserdeffld7			=	TEMP.UserDefFld7,	
								@TEMPuserdeffld8			=	TEMP.UserDefFld8,	
								@TEMPuserdeffld9			=	TEMP.UserDefFld9,	
								@TEMPuserdeffld10			=	TEMP.UserDefFld10,	
								@TEMPuserdeffld11			=	TEMP.UserDefFld11,	
								@TEMPuserdeffld12			=	TEMP.UserDefFld12,	
								@TEMPpoaction				=	TEMP.Poaction,
								@TEMPattention				=	TEMP.Attention,
								@TEMPphone				= 	TEMP.Phone,
								@TEMPext				=	TEMP.Ext,
								@TEMPvoid				=	TEMP.Void
						FROM #TEMPSO TEMP
						WHERE key_table = @key_table					
		
		
						
		
						EXEC @iError = adm_upd_SO
								@order_no                          	=	@TEMPsonumber 		,
								@ship_to                           	=	@TEMPshipto 		,
								@req_ship_date                     	=	@TEMPdeliverydt		,
								@sch_ship_date                     	=	@TEMPshipdt		,
								@terms                             	=	@TEMPterms		,
								@routing                           	=	@TEMPcarrier		,
								@special_instr                     	=	@TEMPshipinst		,
								@salesperson                       	=	@TEMPsalesperson		,
								@tax_id                            	=	@TEMPtax		,
								@fob                               	=	@TEMPfob 		,
								@freight                           	=	@TEMPfreight		,
								@discount                          	=	@TEMPdisc		,
								@cancel_date                       	=	@TEMPcanceldt		,
								@ship_to_add_1                     	=	@TEMPshiptoaddress1 		,
								@ship_to_add_2                     	=	@TEMPshiptoaddress2 		,
								@ship_to_add_3                     	=	@TEMPshiptoaddress3 		,
								@ship_to_add_4                     	=	@TEMPshiptoaddress4 		,
								@ship_to_add_5                     	=	@TEMPshiptoaddress5 		,
								@ship_to_city                      	=	@TEMPshiptocity 		,
								@ship_to_state                     	=	@TEMPshiptostate 		,
								@ship_to_zip                       	=	@TEMPshiptozip 		,
								@ship_to_country                   	=	@TEMPordcountry		,
								@back_ord_flag                     	=	@TEMPbackorder		,
								@note                              	=	@TEMPnote		,
								@forwarder_key                     	=	@TEMPfowarder		,
								@freight_to                        	=	@TEMPfreightto		,
								@freight_allow_type                	=	@TEMPfreighttype		,
								@location                          	=	@TEMPlocation			,
								@blanket                           	=	@TEMPblanket			,
								@curr_key                          	=	@TEMPcurrency			,
								@posting_code                      	=	@TEMPpostingcode		,
								@hold_reason                       	=	@TEMPhold			,
								@so_priority_code                  	=	@TEMPsopriority			,
								@blanket_amt                       	=	@TEMPblanketamount		,
								@user_category                     	=	@TEMPcategory			,
								@from_date                         	=	@TEMPblanketfrom		,
								@to_date                           	=	@TEMPblanketto			,
								@sold_to_addr1                     	=	@TEMPsoldtoaddress1 		,
								@sold_to_addr2                     	=	@TEMPsoldtoaddress2 		,
								@sold_to_addr3                     	=	@TEMPsoldtoaddress3 		,
								@sold_to_addr4                     	=	@TEMPsoldtoaddress4 		,
								@sold_to_addr5                     	=	@TEMPsoldtoaddress5 		,
								@sold_to_addr6                     	=	@TEMPsoldtoaddress6 		,
								@user_code                         	=	@TEMPuserstatus			,
								@user_def_fld1                     	=	@TEMPuserdeffld1		,
								@user_def_fld2                     	=	@TEMPuserdeffld2		,
								@user_def_fld3                     	=	@TEMPuserdeffld3		,
								@user_def_fld4                     	=	@TEMPuserdeffld4		,
								@user_def_fld5                     	=	@TEMPuserdeffld5		,
								@user_def_fld6                     	=	@TEMPuserdeffld6		,
								@user_def_fld7                     	=	@TEMPuserdeffld7		,
								@user_def_fld8                     	=	@TEMPuserdeffld8		,
								@user_def_fld9                     	=	@TEMPuserdeffld9		,
								@user_def_fld10                    	=	@TEMPuserdeffld10		,
								@user_def_fld11                    	=	@TEMPuserdeffld11		,
								@user_def_fld12                    	=	@TEMPuserdeffld12		,
								@sold_to                           	=	@TEMPsoldto			,
								@attention				=	@TEMPattention			,
								@phone					=	@TEMPphone			,
								@consolidate_flag			=	@TEMPconsolidation		,
								@void					= 	@TEMPvoid			,
								@source					=	@source				,
								@ext					=	@TEMPext			,	
								@cust_code				=	@TEMPsoldto,
								@so_no					=	@so_no	OUTPUT
						IF @iError > 1
						BEGIN
							INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 30, @err_section + '', '', 0)	
						END
		
						-------------------------------WHILE-------START---
		
						if @source = 0 
						BEGIN	
									SET @key_table2 = 0
									
									SELECT	@key_table2 = MIN(key_table)
									FROM	#TEMPSOD
									WHERE	key_table > @key_table2
									
					
									set @TEMPwhoentered = suser_name()
					
									WHILE @key_table2 IS NOT NULL
									BEGIN
					
									SELECT 		@TEMPsonumberdet		=	TEMP.SONumber, 
											@TEMPlinenumber			=	TEMP.LineNumber,
											@TEMPpartno			=	TEMP.PartNo, 
											@TEMPtype			=	TEMP.Type, 
											@TEMPquantity			=	TEMP.Quantity, 
											@TEMPunitofmeasure		=	TEMP.UnitOfMeasure, 
											@TEMPloc			=	TEMP.Loc, 
											@TEMPitemdescription		=	TEMP.ItemDescription,
											@TEMPdetailcomment		=	TEMP.DetailComment, 
											@TEMPcompany			=	TEMP.Company,
											@TEMPaccount			=	TEMP.Account, 
											@TEMPcomm			=	TEMP.Comm,
											@TEMPtaxcode			=	TEMP.TaxCode,
											@TEMPcustomer			=	TEMP.Customer,
											@TEMPusercount			=	TEMP.UserCount,
											@TEMPcreatepo			=	TEMP.CreatePO,
											@TEMPbackorderdet		=	TEMP.BackOrder,
											@TEMPreference			=	TEMP.Reference,  
											@TEMPlogin			=	TEMP.Login, 
											@TEMPsoaction			=	TEMP.SOAction, 
											@TEMPprice			=	TEMP.Price, 
											@TEMPfreightdet			=	TEMP.Freight,
											@TEMPpoaction			=	TEMP.Poaction,
											@TEMPitemnote			=	TEMP.ItemNote,
											@TEMPext_d			=	TEMP.Ext	
										FROM #TEMPSOD TEMP
										WHERE key_table = @key_table2 
		
		
		
					
										EXEC @iError = adm_upd_SO_dtl
											@ord_no		=	@TEMPsonumberdet, 	
											@line_no	=	@TEMPlinenumber,	
											@part_no	=	@TEMPpartno, 	
											@type		=	@TEMPtype, 	
											@ordered	=	@TEMPquantity, 	
											@uom		=	@TEMPunitofmeasure, 	
											@location	=	@TEMPloc, 	
											@description	=	@TEMPitemdescription,	
											@detailcomment	=	@TEMPdetailcomment, 	
											@company	=	@TEMPcompany,	
											@account	=	@TEMPaccount, 	
											@comm		=	@TEMPcomm,	
											@taxcode	=	@TEMPtaxcode,	
											@customer	=	@TEMPcustomer,	
											@usercount	=	@TEMPusercount,	
											@createpo	=	@TEMPcreatepo,	
											@backorderdet	=	@TEMPbackorderdet,	
											@reference_code	=	@TEMPreference,  	
											@Who_entered	=	@TEMPlogin, 	
											@soaction	=	@TEMPsoaction, 	
											@price		=	@TEMPprice, 	
											@freight	=	@TEMPfreightdet,	
											@note		=	@TEMPitemnote,
											@ext		=	@TEMPext_d,
											@source		=	@source	
					
						
										IF @iError > 1
										BEGIN
											INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (18000, 40, @err_section + '', '', 0)	
										END
					
					
										SELECT	@key_table2 = MIN(key_table)
										FROM	#TEMPSOD
										WHERE	key_table > @key_table2
					
					
									END
		
		
						SET @key_table2 = 0
						
						SELECT	@key_table2 = MIN(key_table)
						FROM	#TEMPSOD_NEWDET
						WHERE	key_table > @key_table2
						
		
						set @TEMPwhoentered = suser_name()
		
						WHILE @key_table2 IS NOT NULL
						BEGIN
		
		
						SELECT 		@TEMPsonumberdet		=	TEMP.SONumber, 
								@TEMPlinenumber			=	TEMP.LineNumber,
								@TEMPpartno			=	TEMP.PartNo, 
								@TEMPtype			=	TEMP.Type, 
								@TEMPquantity			=	TEMP.Quantity, 
								@TEMPunitofmeasure		=	TEMP.UnitOfMeasure, 
								@TEMPloc			=	TEMP.Loc, 
								@TEMPitemdescription		=	TEMP.ItemDescription,
								@TEMPdetailcomment		=	TEMP.DetailComment, 
								@TEMPcompany			=	TEMP.Company,
								@TEMPaccount			=	TEMP.Account, 
								@TEMPcomm			=	TEMP.Comm,
								@TEMPtaxcode			=	TEMP.TaxCode,
								@TEMPcustomer			=	TEMP.Customer,
								@TEMPusercount			=	TEMP.UserCount,
								@TEMPcreatepo			=	TEMP.CreatePO,
								@TEMPbackorderdet		=	TEMP.BackOrder,
								@TEMPreference			=	TEMP.Reference,  
								@TEMPlogin			=	TEMP.Login, 
								@TEMPsoaction			=	TEMP.SOAction, 
								@TEMPprice			=	TEMP.Price, 
								@TEMPfreightdet			=	TEMP.Freight,
								@TEMPpoaction			=	TEMP.Poaction,
								@TEMPshipto_det			= 	TEMP.ShipTo,
								@TEMPitemnote			=	TEMP.ItemNote
							FROM #TEMPSOD_NEWDET TEMP
								INNER JOIN #TEMPSO TEMP2 ON TEMP.SONumber = TEMP2.SONumber 						
							WHERE TEMP.key_table = @key_table2 AND TEMP2.NewSO = @so_no
		
		
							EXEC @iError = adm_ins_SO_dtl
								@cust_code  	 	= @TEMPcustomer, 
								@cust_po  		= @TEMPsonumberdet,
								@line_no  		= @TEMPlinenumber, 
								@location  		= @TEMPloc, 
								@part_no  		= @TEMPpartno, 
								@ordered    		= @TEMPquantity,
								@uom   			= @TEMPunitofmeasure, 
								@note  			= @TEMPitemnote, 
								@gl_rev_acct  		= @TEMPaccount, 
								@reference_code 	= @TEMPreference,
								@price			= @TEMPprice, 
								@Who_entered 		= @TEMPwhoentered,
								@part_type		= @TEMPtype,
								@description		= @TEMPitemdescription,
								@ship_to		= @TEMPshipto_det
		
		
							IF @iError <> 1
							BEGIN
								INSERT #ewerror (module_id,err_code, info, source, sequence_id) VALUES (19000, 10, @err_section + '', '', 0)	
							END
		
		
							SELECT	@key_table2 = MIN(key_table)
							FROM	#TEMPSOD_NEWDET
							WHERE	key_table > @key_table2
		
		
						END
		
		
		
								
						END
		
						SELECT	@key_table = MIN(key_table)
						FROM	#TEMPSO
						WHERE	key_table > @key_table
		
					END



			SET @key_table = 0
			SET @iError = 0
			SET @so_no = ''
			
			SELECT		@key_table = MIN(key_table)
			FROM		#TEMPSO
			WHERE		key_table > @key_table
			
			select @so_no = SONumber FROM #TEMPSO where key_table = @key_table

			WHILE @key_table IS NOT NULL
			BEGIN

				SET @today = datediff(day, '01/01/1900', getdate()) + 693596
			
				EXEC dbo.fs_calculate_oetax_wrap @ord = @so_no, @ext = 0 , @debug = 0, @batch_call = 1
				EXEC dbo.fs_updordtots @ordno = @so_no, @ordext = 0  




				SELECT		@key_table = MIN(key_table)
				FROM		#TEMPSO
				WHERE		key_table > @key_table

				select @so_no = NewSO FROM #TEMPSO where key_table = @key_table

			END



		END



	END





	IF EXISTS (SELECT 1 FROM #ewerror)
		set @ErrorInd = 1
	

	IF @ErrorInd = 1
	BEGIN
	       SELECT '$FIN_RESULTS$'
	       SELECT '<Description>' + ISNULL((SELECT e_ldesc FROM poerrdef WHERE e_code = 35057),'') + ' </Description>' 
	       SELECT '<ErrorList>' 	
	       SELECT module_id, err_code, 
					RTRIM(LTRIM(DEF.e_ldesc)) AS info, 
					RTRIM(LTRIM(info)) AS SONumber, 
					RTRIM(LTRIM(sequence_id)) AS LineNumber, 
					ISNULL(RTRIM(LTRIM(ERRORS.source)),'') AS value
	       FROM #ewerror AS ERRORS
				INNER JOIN eboerrdef DEF ON err_code = DEF.e_code and DEF.e_type = 'soerr'
	       FOR XML AUTO, ELEMENTS
	       SELECT '</ErrorList>'

	END


	IF @ErrorInd = 0 
	BEGIN
		IF ISNULL(@source, 0) = 1
		BEGIN
		       SELECT '$FIN_RESULTS$'
		       SELECT '<LobId>' + RTRIM(LTRIM(SONumber)) + RTRIM(LTRIM(Ext)) + '</LobId>'
		       FROM #TEMPSO
		END		
	END	


	DROP TABLE #TEMPSO
	DROP TABLE #TEMPSOD





/**/                                              
GO
GRANT EXECUTE ON  [dbo].[IntegrateSO_upd] TO [public]
GO
