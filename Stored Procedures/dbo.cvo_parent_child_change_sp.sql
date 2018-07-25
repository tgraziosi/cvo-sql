SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_parent_child_change_sp]
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS

	-- WORKING TABLES
	CREATE TABLE #parent_child_change (
		parent	varchar(10),
		child	varchar(10))	

	CREATE TABLE #cvo_araging_check (
		parent			varchar(10),
		customer_code	varchar(10))

	-- PROCESSING
	INSERT	#parent_child_change (parent, child)
	SELECT	a.parent, a.rel_cust
	FROM	dbo.artierrl a (NOLOCK)
	LEFT JOIN dbo.cvo_buying_groups_hist b (NOLOCK)
	ON		a.parent = b.parent
	LEFT JOIN dbo.cvo_buying_groups_hist c (NOLOCK)
	ON		a.rel_cust = c.child
	WHERE	a.parent <> a.rel_cust
	AND		b.parent IS NULL
	AND		c.child IS NULL

	INSERT	#cvo_araging_check (parent, customer_code)
	SELECT	DISTINCT a.parent, a.customer_code
	FROM	dbo.cvo_artrxage a (NOLOCK)
	JOIN	#parent_child_change b
	ON		a.customer_code = b.child
	WHERE	a.parent <> b.parent

	UPDATE	a
	SET		parent = b.parent
	FROM	cvo_artrxage a
	JOIN	#parent_child_change b 
	ON		a.customer_code = b.child
	JOIN	#cvo_araging_check c
	ON		a.customer_code = c.customer_code

	-- v1.1 Start
	CREATE TABLE #atf_changes (
		child			varchar(10),
		doc_ctrl_num	varchar(16))

	INSERT	#atf_changes
	SELECT	a.customer_code, a.doc_ctrl_num
	FROM	dbo.cvo_artrxage a (NOLOCK)
	JOIN	cvo_buying_groups_hist b
	ON		a.customer_code = b.child
	WHERE	a.customer_code <> a.parent
	AND		a.parent =  b.parent
	AND		b.end_date IS NOT NULL
	AND		b.end_date < a.doc_date

	UPDATE	a
	SET		parent = b.child
	FROM	dbo.cvo_artrxage a
	JOIN	#atf_changes b
	ON		a.doc_ctrl_num = b.doc_ctrl_num
	AND		a.customer_code = b.child

	DROP TABLE #atf_changes
	-- v1.1 End

	-- CLEAN UP
	DROP TABLE #parent_child_change
	DROP TABLE #cvo_araging_check

END
GO
GRANT EXECUTE ON  [dbo].[cvo_parent_child_change_sp] TO [public]
GO
