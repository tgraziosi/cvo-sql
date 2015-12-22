SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                


CREATE PROC [dbo].[iblink1_sp] @WhereClause varchar(256)
AS
	DECLARE @groupby varchar(128)
	DECLARE @string1 varchar(1024)

	SELECT @groupby = ' GROUP BY id, trx_type, data, info_desc'

	CREATE TABLE #iblink
	(
		id 		varchar(36),
		info_desc	varchar(30),
		trx_type	varchar(60),
		data		varchar(16)
	)


	INSERT INTO #iblink
	(
		id,
		info_desc,
		trx_type,
		data
	)
		SELECT	id,
			'Generated Journal',
			t.description,
			trx_ctrl_num
		FROM iblink l
		INNER JOIN ibtrxtype t
			ON l.trx_type = t.trx_type
		WHERE sequence_id = 2


	INSERT INTO #iblink
	(
		id,
		info_desc,
		trx_type,
		data
	)
		SELECT	id,
			'From Journal',
			t.description,
			trx_ctrl_num = CASE WHEN trx_ctrl_num IN (SELECT data FROM #iblink) THEN 'External'
					ELSE trx_ctrl_num END
		FROM iblink l
		INNER JOIN ibtrxtype t
			ON l.trx_type = t.trx_type
		WHERE sequence_id = 3


	INSERT INTO #iblink
	(
		id,
		info_desc,
		trx_type,
		data
	)
		SELECT	l.id,
			'URL',
			t.description,
			l.source_url
		FROM iblink l
		INNER JOIN ibtrxtype t
			ON l.trx_type = t.trx_type
		INNER JOIN ibhdr h
			ON h.id = l.id
		WHERE l.sequence_id = 1
	
	INSERT INTO #iblink
	(
		id,
		info_desc,
		trx_type,
		data
	)
		SELECT	l.id,
			'URN',
			t.description,
			l.source_urn
		FROM iblink l
		INNER JOIN ibtrxtype t
			ON l.trx_type = t.trx_type
		INNER JOIN ibhdr h
			ON h.id = l.id
		WHERE l.sequence_id = 1
	


	SELECT @string1 = 'SELECT id, info_desc, trx_type, data FROM #iblink '+ @WhereClause + @groupby

	EXEC(@string1)
GO
GRANT EXECUTE ON  [dbo].[iblink1_sp] TO [public]
GO
