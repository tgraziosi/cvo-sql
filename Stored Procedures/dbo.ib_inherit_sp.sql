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

















CREATE PROCEDURE [dbo].[ib_inherit_sp]
	@org_id varchar(30)

AS

DECLARE @result int

CREATE TABLE #inherit_setup
(
	org_id varchar(30),
	mark_flag smallint NULL
)

CREATE TABLE #inherit_security
(
	org_id varchar(30),
	mark_flag smallint NULL
)

INSERT #inherit_setup
	(
		org_id,
		mark_flag
	)
SELECT			
	child_org_id,
	0
FROM IBAllChilds_vw i
	INNER JOIN Organization o 
	ON i.child_org_id = o.organization_id
	WHERE parent_org_id = @org_id
ORDER BY LEN (parent_outline_num), parent_outline_num, LEN (child_outline_num), child_outline_num

INSERT #inherit_security
	(
		org_id,
		mark_flag
	)
SELECT			
	child_org_id,
	0
FROM IBAllChilds_vw i
	INNER JOIN Organization o 
	ON i.child_org_id = o.organization_id
	WHERE parent_org_id = @org_id
ORDER BY LEN (parent_outline_num), parent_outline_num, LEN (child_outline_num), child_outline_num


EXEC @result = ib_copy_setup_sp @org_id	
EXEC @result = ib_copy_security_sp @org_id

WHILE (1=1)
BEGIN
	SET ROWCOUNT 1

	SELECT @org_id = org_id 
	FROM #inherit_setup
		WHERE mark_flag = 0

	IF @@rowcount = 0 break

	SET ROWCOUNT 0
		EXEC @result = ib_copy_setup_sp @org_id	

	IF(@result != 0)
		RETURN @result


		SET ROWCOUNT 1
		UPDATE #inherit_setup
		SET mark_flag = 1
		WHERE org_id = @org_id
		AND mark_flag = 0
		SET ROWCOUNT 0

END

WHILE (1=1)
BEGIN
	SET ROWCOUNT 1

	SELECT @org_id = org_id 
	FROM #inherit_security
		WHERE mark_flag = 0

	IF @@rowcount = 0 break

	SET ROWCOUNT 0
		EXEC @result = ib_copy_security_sp @org_id	

	IF(@result != 0)
		RETURN @result


		SET ROWCOUNT 1
		UPDATE #inherit_security
		SET mark_flag = 1
		WHERE org_id = @org_id
		AND mark_flag = 0
		SET ROWCOUNT 0

END

GO
GRANT EXECUTE ON  [dbo].[ib_inherit_sp] TO [public]
GO
