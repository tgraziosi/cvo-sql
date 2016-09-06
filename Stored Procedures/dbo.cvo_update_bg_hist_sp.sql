SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_update_bg_hist_sp]	@parent		varchar(10),
										@relation	varchar(10),
										@user_name	varchar(50)
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- Write audit
	INSERT	dbo.cvo_buying_group_switch_audit ( audit_date, userid, rec_type, parent, child, buying_group_no, action_date)
	SELECT	GETDATE(), suser_name(), 'NEW RECORD', a.parent, a.child, a.buying_group_no, CONVERT(varchar(10),DATEADD(DAY, a.action_date - 693596, '01/01/1900'),121)
	FROM	#tmpArnarel a
	LEFT JOIN
			cvo_buying_groups_hist b 
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	AND		a.action_date = b.end_date_int
	WHERE	a.action = 'U'
	AND		b.child IS NULL
	AND		b.end_date IS NULL
	AND		a.parent = @parent
	AND		a.relation_code = @relation

	-- Write audit
	INSERT	dbo.cvo_buying_group_switch_audit ( audit_date, userid, rec_type, parent, child, buying_group_no, action_date)
	SELECT	GETDATE(), suser_name(), 'DELETE RECORD', a.parent, a.child, a.buying_group_no, CONVERT(varchar(10),DATEADD(DAY, b.action_date - 693596, '01/01/1900'),121)
	FROM	cvo_buying_groups_hist a
	JOIN	#tmpArnarel b
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	WHERE	b.action = 'D'
	AND		a.parent = @parent
	AND		a.relation_code = @relation

	-- Write audit
	INSERT	dbo.cvo_buying_group_switch_audit ( audit_date, userid, rec_type, parent, child, buying_group_no, action_date)
	SELECT	DISTINCT GETDATE(), suser_name(), 'BUYING GROUP NUMBER CHANGE FROM ' + a.buying_group_no, a.parent, a.child, b.buying_group_no, CONVERT(varchar(10),DATEADD(DAY, b.action_date - 693596, '01/01/1900'),121)
	FROM	cvo_buying_groups_hist a
	JOIN	#tmpArnarel b
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	WHERE	b.bg_changed = 'Y'
	AND		a.buying_group_no <> b.buying_group_no	
	AND		a.parent = @parent
	AND		a.relation_code = @relation

	-- Inserts 
	INSERT	dbo.cvo_buying_groups_hist (parent, child, relation_code, start_date_int, start_date, 
			end_date_int, end_date, buying_group_no, modified_by, modified_on_int, modified_on)	
	SELECT	a.parent,
			a.child,
			a.relation_code,
			a.action_date,
			CONVERT(varchar(10),DATEADD(DAY, a.action_date - 693596, '01/01/1900'),121),
			NULL, NULL,
			a.buying_group_no,
			@user_name,
			DATEDIFF(DAY, '01/01/1900', GETDATE()) + 693596,		
			CONVERT(varchar(10),GETDATE(),121)
	FROM	#tmpArnarel a
	LEFT JOIN
			cvo_buying_groups_hist b 
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	AND		a.action_date = b.end_date_int
	WHERE	a.action = 'U'
	AND		b.child IS NULL
	AND		b.end_date IS NULL
	AND		a.parent = @parent
	AND		a.relation_code = @relation

	-- Deletes
	UPDATE	a
	SET		end_date_int = b.action_date,
			end_date = CONVERT(varchar(10),DATEADD(DAY, b.action_date - 693596, '01/01/1900'),121),
			modified_by = @user_name,
			modified_on_int = DATEDIFF(DAY, '01/01/1900', GETDATE()) + 693596,		
			modified_on = CONVERT(varchar(10),GETDATE(),121)
	FROM	cvo_buying_groups_hist a
	JOIN	#tmpArnarel b
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	WHERE	b.action = 'D'
	AND		a.parent = @parent
	AND		a.relation_code = @relation
	AND		end_date IS NULL -- v1.1

	-- Buying group number updates
	UPDATE	a
	SET		buying_group_no = b.buying_group_no,
			modified_by = @user_name,
			modified_on_int = DATEDIFF(DAY, '01/01/1900', GETDATE()) + 693596,		
			modified_on = CONVERT(varchar(10),GETDATE(),121)
	FROM	cvo_buying_groups_hist a
	JOIN	#tmpArnarel b
	ON		a.parent = b.parent
	AND		a.relation_code = b.relation_code
	AND		a.child = b.child
	WHERE	b.bg_changed = 'Y'
	AND		a.buying_group_no <> b.buying_group_no	
	AND		a.parent = @parent
	AND		a.relation_code = @relation
  
	UPDATE	a
	SET		ftp = b.buying_group_no
	FROM	arcustok_vw a
	JOIN	#tmpArnarel b
	ON		a.customer_code = b.child
	WHERE	b.bg_changed = 'Y'
	AND		a.ftp <> b.buying_group_no	
	AND		b.parent = @parent
	AND		b.relation_code = @relation
	
	UPDATE	a
	SET		ftp = ''
	FROM	arcustok_vw a
	JOIN	#tmpArnarel b
	ON		a.customer_code = b.child
	WHERE	b.action = 'D'
	AND		b.parent = @parent
	AND		b.relation_code = @relation

END
GO
GRANT EXECUTE ON  [dbo].[cvo_update_bg_hist_sp] TO [public]
GO
