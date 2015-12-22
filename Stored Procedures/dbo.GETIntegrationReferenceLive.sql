SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[GETIntegrationReferenceLive] (@InputXml AS NTEXT = NULL)
AS

DECLARE @ret_status INTEGER
DECLARE @hDoc INTEGER

CREATE TABLE #TEMPInfo
(
	timestamp		timestamp,
	reference_code	varchar(32),
	description		varchar(40),
	reference_type	varchar(8),
	status_flag		smallint,
	status			VARCHAR(1),
	reference_flag	SMALLINT,
	record_type		VARCHAR(32)
)
/*
CREATE UNIQUE CLUSTERED INDEX GETIntegrationReferenceLive_TempInfo_ind_0
	ON #TEMPInfo ( reference_code )

CREATE INDEX GETIntegrationReferenceLive_TempInfo_ind_1
	ON #TEMPInfo ( reference_type, reference_code )
*/

CREATE TABLE #TEMPReferenceCodes(
	id VARCHAR(32),
	reftype VARCHAR(32),
	status VARCHAR(1))

CREATE TABLE #TEMPReferenceTypes(
	id VARCHAR(32),
	mask VARCHAR(32),
	status VARCHAR(1))

EXEC @ret_status = sp_xml_preparedocument @hDoc OUTPUT, @InputXml, '<root xmlns:x="http://Epicor.com/BackOfficeGl/GetAccountsRequest"/>'

INSERT INTO #TEMPReferenceCodes
	SELECT 	[id],
			[reftype],
			[status]
	FROM OPENXML (@hDoc, '//x:root/x:refcodes/x:refcode', 2)
	WITH (	id VARCHAR(32) './x:id', 
			reftype VARCHAR(32) './x:reftype',
			status VARCHAR(1) './x:status')

INSERT INTO #TEMPReferenceTypes
	SELECT 	[id],
			[mask],
			[status]
	FROM OPENXML (@hDoc, '//x:root/x:reftypes/x:reftype', 2)
	WITH (	id VARCHAR(32) './x:id', 
			mask VARCHAR(32) './x:mask',
			status VARCHAR(1) './x:status')


EXEC sp_xml_removedocument @hDoc


/*--------------------------------------------------------------------------------------------------------------------*/
--GET REFERENCE CODES
/*--------------------------------------------------------------------------------------------------------------------*/
INSERT INTO #TEMPInfo (reference_code, description, reference_type, status_flag, status, record_type)
SELECT Distinct REF.reference_code, REF.description, REF.reference_type, REF.status_flag, COD.status, 'ReferenceCode'
FROM glref REF
	INNER JOIN #TEMPReferenceCodes COD ON REF.reference_code = COD.id AND REF.reference_type = COD.reftype

/*--------------------------------------------------------------------------------------------------------------------*/
--GET REFERENCE TYPES
/*--------------------------------------------------------------------------------------------------------------------*/
INSERT INTO #TEMPInfo (reference_code, reference_type, status, reference_flag, record_type)
SELECT Distinct REF.account_mask, TYP.id, TYP.status, FAC.reference_flag, 'ReferenceType'
FROM glratyp REF
	INNER JOIN glrefact FAC ON REF.account_mask = FAC.account_mask
	INNER JOIN #TEMPReferenceTypes TYP ON REF.account_mask = TYP.mask /* AND REF.reference_type = TYP.id*/
	INNER JOIN glref RF ON RF.reference_type = TYP.id

INSERT INTO #TEMPInfo (reference_code, reference_type, status, reference_flag, record_type)
SELECT Distinct TYP.mask, TYP.id, TYP.status, 1,'ReferenceType'
FROM glreftyp REF
	INNER JOIN #TEMPReferenceTypes TYP ON REF.reference_type = TYP.id 
	LEFT JOIN glrefact FAC ON TYP.mask = FAC.account_mask
WHERE FAC.account_mask IS NULL AND TYP.status = 'D'
	
SELECT reference_code, description, reference_type, status_flag, status, reference_flag, record_type
FROM #TEMPInfo


GO
GRANT EXECUTE ON  [dbo].[GETIntegrationReferenceLive] TO [public]
GO
