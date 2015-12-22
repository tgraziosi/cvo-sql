SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GETIntegrationCOASLive] (@InputXml AS NTEXT = NULL)
AS


DECLARE @ret_status INTEGER
DECLARE @hDoc INTEGER

CREATE TABLE #TEMPInfo
(
	timestamp			timestamp,
	account_code		varchar(32),
	account_description	varchar(40),
	account_type		smallint,
	new_flag			smallint,	
	seg1_code			varchar(40),	
	seg2_code			varchar(40),
	seg3_code			varchar(40),
	seg4_code			varchar(40),
	consol_detail_flag	smallint,
	consol_type			smallint,
	active_date			int,
	inactive_date		int,
	inactive_flag		smallint,
	currency_code		varchar(8),
    revaluate_flag      smallint,
    rate_type_home      varchar(8) NULL,
    rate_type_oper      varchar(8) NULL,
	status				VARCHAR(1),
	record_type			VARCHAR(32)
)
/*
CREATE UNIQUE NONCLUSTERED INDEX GETIntegrationCOASLive_TEMPInfo_ind_0
	 ON #TEMPInfo ( account_code )

CREATE INDEX GETIntegrationCOASLive_TEMPInfo_ind_1
	 ON #TEMPInfo ( account_type, account_code )
*/
CREATE TABLE #TEMPAccounts(
	id VARCHAR(32),
	status VARCHAR(1))


/*--------------------------------------------------------------------------------------------------------------------*/
--GET ACCOUNT
/*--------------------------------------------------------------------------------------------------------------------*/

EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @InputXml, '<root xmlns:x="http://Epicor.com/BackOfficeGl/GetAccountsRequest"/>'

INSERT INTO #TEMPAccounts 
	SELECT 	[id],
			[status]
	FROM OPENXML (@hDoc, '//x:root/x:accounts/x:account', 2)
	WITH (	id VARCHAR(32) './x:id', 
			status VARCHAR(1) './x:status')

EXEC sp_xml_removedocument @hDoc


INSERT INTO #TEMPInfo (	account_code,			account_description,			account_type, 
						new_flag,				seg1_code,						seg2_code, 
						seg3_code,				seg4_code,						consol_detail_flag, 
						consol_type,			active_date,					inactive_date, 
						inactive_flag,			currency_code,					revaluate_flag, 
						rate_type_home,			rate_type_oper,					status, 
						record_type)
SELECT CHRT.account_code,			CHRT.account_description,			CHRT.account_type, 
		CHRT.new_flag,				SEG1.short_desc,					SEG2.short_desc, 
		SEG3.short_desc,			SEG4.short_desc,					CHRT.consol_detail_flag, 
		CHRT.consol_type,			CHRT.active_date,					CHRT.inactive_date, 
		CHRT.inactive_flag,			CHRT.currency_code,					CHRT.revaluate_flag, 
		CHRT.rate_type_home,		CHRT.rate_type_oper,				TEMP.status, 
		'Account'
FROM glchart CHRT
	INNER JOIN #TEMPAccounts TEMP ON CHRT.account_code = TEMP.id
	LEFT JOIN glseg1 SEG1 ON CHRT.seg1_code = SEG1.seg_code
	LEFT JOIN glseg2 SEG2 ON CHRT.seg2_code = SEG2.seg_code
	LEFT JOIN glseg3 SEG3 ON CHRT.seg3_code = SEG3.seg_code
	LEFT JOIN glseg4 SEG4 ON CHRT.seg4_code = SEG4.seg_code

/*--------------------------------------------------------------------------------------------------------------------*/
--GET ACCOUNT DEFINITION
/*--------------------------------------------------------------------------------------------------------------------*/

INSERT INTO #TEMPInfo (	account_code,			account_description,			seg1_code,						
						seg2_code,				seg3_code,						seg4_code,
						record_type)
SELECT DEF.acct_format,			DEF.description,			DEF.start_col,
		DEF.length,				DEF.acct_level,				DEF.natural_acct_flag,
		'Definition'
FROM glaccdef DEF

/*--------------------------------------------------------------------------------------------------------------------*/
--GET COMPANY
/*--------------------------------------------------------------------------------------------------------------------*/

INSERT INTO #TEMPInfo (	account_code,			account_description,		record_type)
SELECT CO.company_id,		CO.company_name,		'Company'
FROM glco CO



SELECT account_code,			account_description,			account_type, 
		new_flag,				seg1_code,						seg2_code, 
		seg3_code,				seg4_code,						consol_detail_flag, 
		consol_type,			active_date,					inactive_date, 
		inactive_flag,			currency_code,					revaluate_flag, 
		rate_type_home,			rate_type_oper,					status, 
		record_type
FROM #TEMPInfo


DROP TABLE #TEMPInfo
DROP TABLE #TEMPAccounts
GO
GRANT EXECUTE ON  [dbo].[GETIntegrationCOASLive] TO [public]
GO
