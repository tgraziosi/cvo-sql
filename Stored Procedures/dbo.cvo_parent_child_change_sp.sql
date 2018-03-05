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
	FROM	dbo.cvo_artrxage a
	JOIN	#parent_child_change b 
	ON		a.customer_code = b.child
	JOIN	#cvo_araging_check c
	ON		a.customer_code = c.customer_code

	-- CLEAN UP
	DROP TABLE #parent_child_change
	DROP TABLE #cvo_araging_check

END
GO
GRANT EXECUTE ON  [dbo].[cvo_parent_child_change_sp] TO [public]
GO
