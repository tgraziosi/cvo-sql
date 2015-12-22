SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[cvo_bg_get_document_data_sp] @customer_code	varchar(10) = NULL,
											@type int = 0,
											@stm_type char(3) = '',
											@stm_range varchar(5000) = '' -- v1.9
AS
BEGIN
	-- DIRECTIVES
	SET NOCOUNT ON
	SET QUOTED_IDENTIFIER OFF

	-- DECLARATIONS
	DECLARE	@IsParent		int,
			@IsBG			int,
			@row_id			int,
			@last_row_id	int,
			@relation_code varchar(10),
			@SQL			varchar(6000) -- v1.9

	-- Create Working Tables
	CREATE TABLE #removed_child (
		parent			varchar(10),
		customer_code	varchar(10),
		remove_date_int	int,
		remove_date		varchar(10))

	CREATE TABLE #joined_child (
		parent			varchar(10),
		customer_code	varchar(10),
		start_date_int	int,
		start_date		varchar(10))

	CREATE TABLE #joinremove_child (
		parent			varchar(10),
		child			varchar(10),
		start_date_int	int,
		start_date		varchar(10),
		remove_date_int	int,
		remove_date		varchar(10))

	CREATE TABLE #joinremove_child_distinct (
		row_id			int IDENTITY(1,1),
		parent			varchar(10),
		child			varchar(10),
		start_date_int	int,
		start_date		varchar(10),
		remove_date_int	int,
		remove_date		varchar(10))

	CREATE TABLE #IncCust (
		parent		varchar(10),
		child		varchar(10))

	CREATE TABLE #order_data (
		order_no		int,
		order_ext		int,
		order_ctrl_num	varchar(20),
		user_category	varchar(20),
		buying_group	varchar(10),
		cust_code		varchar(10))

	CREATE TABLE #bg_data_detail (
		doc_ctrl_num	varchar(16),
		order_ctrl_num	varchar(16),
		apply_to_num	varchar(16),
		customer_code	varchar(10),
		doc_date_int	int,
		doc_date		varchar(10),
		parent			varchar(10))


	-- Processing

-- v2.1 Start
	INSERT	#order_data (order_no, order_ext, order_ctrl_num, user_category, buying_group, cust_code)
	SELECT  order_no, order_ext, order_ctrl_num, user_category, buying_group, cust_code
	FROM	cvo_rb_data (NOLOCK)

--	SELECT	a.order_no, a.ext, CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)), a.user_category, ISNULL(b.buying_group,''), a.cust_code
--	FROM	orders_all a (NOLOCK)
--	JOIN	cvo_orders_all b (NOLOCK)
--	ON		a.order_no = b.order_no
--	AND		a.ext = b.ext
--	WHERE	RIGHT(a.user_category,2) = 'RB'
-- v2.1 End

	-- v2.0 Start
	DELETE	a
	FROM	#order_data a
	LEFT JOIN	cvo_buying_groups_hist b (NOLOCK)
	ON		a.cust_code = b.child
	WHERE	b.child IS NULL
	-- v2.0 End

	IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#order_data' ) AND name = '#order_data_ind0' ) 
		DROP INDEX #order_data.#order_data_ind0

	CREATE INDEX #order_data_ind0 ON #order_data(order_ctrl_num)

	IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#order_data' ) AND name = '#order_data_ind1' ) 
		DROP INDEX #order_data.#order_data_ind1

	CREATE INDEX #order_data_ind1 ON #order_data(buying_group, cust_code)


	SELECT  @relation_code = credit_check_rel_code    
	FROM   arco (NOLOCK)    

	SET @IsParent = 0
	SET @IsBG = 0
	IF (@customer_code IS NOT NULL) -- start customer_code passed in
	BEGIN
		SELECT	@IsParent = 1
		FROM	arnarel (NOLOCK)
		WHERE	parent = @customer_code
		AND		relation_code = @relation_code

		IF (@IsParent = 1) -- Start of Isparent
		BEGIN
			SELECT	@IsBG = 1
			FROM	arcust (NOLOCK)
			WHERE	customer_code = @customer_code
			AND		UPPER(addr_sort1) = 'BUYING GROUP'

			IF (@IsBg = 1) -- start of IsBG = 1
			BEGIN
				INSERT	#removed_child (parent, customer_code, remove_date_int, remove_date)
				SELECT	parent, child, end_date_int, end_date
				FROM	cvo_buying_groups_hist (NOLOCK) 
				WHERE	parent = @customer_code 
				AND		end_date_int IS NOT NULL

				INSERT	#joined_child (parent, customer_code, start_date_int, start_date)
				SELECT	parent, child, start_date_int, start_date
				FROM	cvo_buying_groups_hist (NOLOCK) 
				WHERE	parent = @customer_code 

				INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
						CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
				FROM	cvo_buying_groups_hist a (NOLOCK)
				JOIN	#joined_child b
				ON		a.parent = b.parent
				AND		a.child = b.customer_code
				JOIN	#removed_child c
				ON		a.parent = c.parent
				AND		a.child = c.customer_code		
				WHERE	a.start_date_int = b.start_date_int

				INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
						CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
				FROM	cvo_buying_groups_hist a (NOLOCK)
				JOIN	#removed_child b
				ON		a.parent = b.parent
				AND		a.child = b.customer_code
				JOIN	#joined_child c
				ON		a.parent = c.parent
				AND		a.child = c.customer_code		
				LEFT JOIN #joinremove_child d
				ON		a.parent = d.parent
				AND		a.child = d.child
				WHERE	a.end_date_int = b.remove_date_int
				AND		d.parent IS NULL
				AND		d.child IS NULL
				AND		d.start_date IS NULL

				INSERT	#joinremove_child_distinct (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	DISTINCT parent, child, start_date_int, start_date, remove_date_int, remove_date 
				FROM	#joinremove_child
				ORDER BY parent, child, start_date

				DROP TABLE #joinremove_child

				DELETE	a
				FROM	#removed_child a
				JOIN	#joinremove_child_distinct b
				ON		a.parent = b.parent
				AND		a.customer_code = b.child
				AND		a.remove_date_int = b.remove_date_int

				DELETE	a
				FROM	#joined_child a
				JOIN	#joinremove_child_distinct b
				ON		a.parent = b.parent
				AND		a.customer_code = b.child
				AND		a.start_date_int = b.start_date_int

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#removed_child' ) AND name = '#removed_child_ind0' ) 
					DROP INDEX #removed_child.#removed_child_ind0

				CREATE INDEX #removed_child_ind0 ON #removed_child (parent, customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joined_child' ) AND name = '#joined_child_ind0' ) 
					DROP INDEX #joined_child.#joined_child_ind0

				CREATE INDEX #joined_child_ind0 ON #joined_child (parent, customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joinremove_child_distinct' ) AND name = '#joinremove_child_distinct_ind0' ) 
					DROP INDEX #joinremove_child_distinct.#joinremove_child_distinct_ind0

				CREATE INDEX #joinremove_child_distinct_ind0 ON #joinremove_child_distinct (parent, child)


				INSERT	#IncCust
				SELECT	parent, customer_code
				FROM	#joined_child

				INSERT	#IncCust
				SELECT	a.parent, a.customer_code
				FROM	#removed_child a 
				LEFT JOIN #IncCust b
				ON		a.parent = b.parent
				AND		a.customer_code = b.child
				WHERE	b.parent IS NULL
				AND		b.child IS NULL

				INSERT	#IncCust
				SELECT	a.parent, a.child
				FROM	#joinremove_child_distinct a 
				LEFT JOIN #IncCust b
				ON		a.parent = b.parent
				AND		a.child = b.child
				WHERE	b.parent IS NULL
				AND		b.child IS NULL

				INSERT	#IncCust
				SELECT	DISTINCT a.buying_group, a.cust_code
				FROM	#order_data a
				LEFT JOIN #IncCust c
				ON		a.buying_group = c.parent
				AND		a.cust_code = c.child
				WHERE	a.buying_group = @customer_code
				AND		c.parent IS NULL
				AND		c.child IS NULL

				INSERT	#IncCust
				SELECT	@customer_code, @customer_code

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#IncCust' ) AND name = '#IncCust_ind0' ) 
					DROP INDEX #IncCust.#IncCust_ind0

				CREATE INDEX #IncCust_ind0 ON #IncCust (parent, child)

				IF (@type = 0)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT doc_ctrl_num,
							CASE WHEN trx_type IN (2031,2032,2161) THEN order_ctrl_num ELSE '' END, -- v1.1
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	artrxage a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

				END
				IF (@type = 1)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT trx_ctrl_num,
							CASE WHEN trx_type IN (2031,2032) THEN order_ctrl_num ELSE '' END,
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	arinpchg_all a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT trx_ctrl_num,
							'',
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	arinppyt_all a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

				END
				IF (@type = 2)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT 'SO',
							CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)),
							a.cust_code,
							CASE WHEN a.invoice_date IS NULL 
								THEN DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.date_entered,121)) + 693596 
								ELSE DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.invoice_date,121)) + 693596
							END,
							CASE WHEN a.invoice_date IS NULL 
								THEN CONVERT(varchar(10), a.date_entered,121)
								ELSE CONVERT(varchar(10), a.invoice_date,121)
							END,
							CASE WHEN b.buying_group IS NULL THEN '' ELSE b.buying_group END
					FROM	orders_all a (NOLOCK)
					JOIN	cvo_orders_all b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.ext = b.ext
					JOIN	#IncCust c
					ON		a.cust_code = c.child
				END

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind0' ) 
					DROP INDEX #bg_data.#bg_data_ind0

				CREATE INDEX #bg_data_ind0 ON #bg_data (customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind1' ) 
					DROP INDEX #bg_data.#bg_data_ind1

				CREATE INDEX #bg_data_ind1 ON #bg_data (customer_code, doc_date_int)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind2' ) 
					DROP INDEX #bg_data.#bg_data_ind2

				CREATE INDEX #bg_data_ind2 ON #bg_data (order_ctrl_num)

				-- v2.2 Start
				UPDATE	a
				SET		doc_date_int = c.doc_date_int,
						doc_date = CONVERT(varchar(10),DATEADD(day, c.doc_date_int - 693596, '1900-01-01'),121)  
				FROM	#bg_data a
				JOIN	artrxage b(NOLOCK)
				ON		a.customer_code = b.customer_code
				AND		a.doc_ctrl_num = b.doc_ctrl_num
				JOIN	#bg_data c
				ON		a.customer_code = b.customer_code	
				AND		b.apply_to_num = c.doc_ctrl_num
				WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')

				UPDATE	c
				SET		doc_date_int = a.date_doc,
						doc_date = CONVERT(varchar(10),DATEADD(day, a.date_doc - 693596, '1900-01-01'),121)  
				FROM	artrxage a (NOLOCK)
				JOIN	artrxage b (NOLOCK)
				ON		a.doc_ctrl_num = b.apply_to_num
				AND		a.customer_code = b.customer_code	
				JOIN	#bg_data c
				ON		b.customer_code = c.customer_code	
				AND		b.doc_ctrl_num = c.doc_ctrl_num
				WHERE	a.trx_type = 2031
				AND		b.trx_type = 2111
				AND		LEFT(b.trx_ctrl_num,2) = 'CB'
				-- v2.2 End

				UPDATE	a
				SET		parent = @customer_code
				FROM	#bg_data a
				JOIN	#removed_child b
				ON		a.customer_code = b.customer_code
				WHERE	a.doc_date_int <= b.remove_date_int
				AND		b.parent = @customer_code

				UPDATE	a
				SET		parent = @customer_code
				FROM	#bg_data a
				JOIN	#joined_child b
				ON		a.customer_code = b.customer_code
				WHERE	a.doc_date_int >= b.start_date_int
				AND		b.parent = @customer_code

				UPDATE	#bg_data
				SET		parent = customer_code
				WHERE	customer_code = @customer_code

				SET @last_row_id = 0

				SELECT	TOP 1 @row_id = row_id
				FROM	#joinremove_child_distinct
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC

				WHILE (@@ROWCOUNT <> 0)
				BEGIN

					UPDATE	a
					SET		parent = @customer_code
					FROM	#bg_data a
					JOIN	#joinremove_child_distinct b
					ON		a.customer_code = b.child
					WHERE	a.doc_date_int >= b.start_date_int
					AND		a.doc_date_int <= b.remove_date_int
					AND		b.row_id = @row_id				

					SET @last_row_id = @row_id

					SELECT	TOP 1 @row_id = row_id
					FROM	#joinremove_child_distinct
					WHERE	row_id > @last_row_id
					ORDER BY row_id ASC
				END

				UPDATE	a
				SET		parent = CASE WHEN ISNULL(b.buying_group,'') = '' THEN a.customer_code ELSE ISNULL(b.buying_group,'') END
				FROM	#bg_data a
				JOIN	#order_data b
				ON		a.order_ctrl_num = b.order_ctrl_num

				DELETE	#bg_data
				WHERE	parent <> @customer_code

			END -- End of IsBG = 1
			ELSE
			BEGIN -- Start of IsBG = 0
				INSERT	#IncCust
				SELECT	parent, rel_cust
				FROM	artierrl (NOLOCK)
				WHERE	parent = @customer_code
				AND		tier_level > 1				
				AND		relation_code = @relation_code

				INSERT	#IncCust
				SELECT	@customer_code, @customer_code

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#IncCust' ) AND name = '#IncCust_ind1' ) 
					DROP INDEX #IncCust.#IncCust_ind1

				CREATE INDEX #IncCust_ind1 ON #IncCust (parent, child)

				INSERT	#removed_child (parent, customer_code, remove_date_int, remove_date)
				SELECT	a.parent, a.child, a.end_date_int, a.end_date
				FROM	cvo_buying_groups_hist a (NOLOCK) 
				JOIN	#IncCust b
				ON		a.child = b.child
				WHERE	end_date_int IS NOT NULL

				INSERT	#joined_child (parent, customer_code, start_date_int, start_date)
				SELECT	a.parent, a.child, a.start_date_int, a.start_date
				FROM	cvo_buying_groups_hist a (NOLOCK) 
				JOIN	#IncCust b
				ON		a.child = b.child

				INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
						CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
				FROM	cvo_buying_groups_hist a (NOLOCK)
				JOIN	#joined_child b
				ON		a.parent = b.parent
				AND		a.child = b.customer_code
				JOIN	#removed_child c
				ON		a.parent = c.parent
				AND		a.child = c.customer_code		
				WHERE	a.start_date_int = b.start_date_int

				INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
						CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
				FROM	cvo_buying_groups_hist a (NOLOCK)
				JOIN	#removed_child b
				ON		a.parent = b.parent
				AND		a.child = b.customer_code
				JOIN	#joined_child c
				ON		a.parent = c.parent
				AND		a.child = c.customer_code		
				LEFT JOIN #joinremove_child d
				ON		a.parent = d.parent
				AND		a.child = d.child
				WHERE	a.end_date_int = b.remove_date_int
				AND		d.parent IS NULL
				AND		d.child IS NULL
				AND		d.start_date IS NULL

				INSERT	#joinremove_child_distinct (parent, child, start_date_int, start_date, remove_date_int, remove_date)
				SELECT	DISTINCT parent, child, start_date_int, start_date, remove_date_int, remove_date 
				FROM	#joinremove_child
				ORDER BY parent, child, start_date

				DROP TABLE #joinremove_child

				DELETE	a
				FROM	#removed_child a
				JOIN	#joinremove_child_distinct b
				ON		a.parent = b.parent
				AND		a.customer_code = b.child
				AND		a.remove_date_int = b.remove_date_int

				DELETE	a
				FROM	#joined_child a
				JOIN	#joinremove_child_distinct b
				ON		a.parent = b.parent
				AND		a.customer_code = b.child
				AND		a.start_date_int = b.start_date_int
				
				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#removed_child' ) AND name = '#removed_child_ind1' ) 
					DROP INDEX #removed_child.#removed_child_ind1

				CREATE INDEX #removed_child_ind1 ON #removed_child (parent, customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joined_child' ) AND name = '#joined_child_ind1' ) 
					DROP INDEX #joined_child.#joined_child_ind1

				CREATE INDEX #joined_child_ind1 ON #joined_child (parent, customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joinremove_child_distinct' ) AND name = '#joinremove_child_distinct_ind1' ) 
					DROP INDEX #joinremove_child_distinct.#joinremove_child_distinct_ind1

				CREATE INDEX #joinremove_child_distinct_ind1 ON #joinremove_child_distinct (parent, child)


				IF (@type = 0)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT doc_ctrl_num,
							CASE WHEN trx_type IN (2031,2032,2161) THEN order_ctrl_num ELSE '' END, -- v1.1
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	artrxage a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

				END
				IF (@type = 1)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT trx_ctrl_num,
							CASE WHEN trx_type IN (2031,2032) THEN order_ctrl_num ELSE '' END,
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	arinpchg_all a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT trx_ctrl_num,
							'',
							customer_code,
							date_doc,
							CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
							''
					FROM	arinppyt_all a (NOLOCK)
					JOIN	#IncCust b
					ON		a.customer_code = b.child

				END
				IF (@type = 2)
				BEGIN
					INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
					SELECT	DISTINCT 'SO',
							CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)),
							a.cust_code,
							CASE WHEN a.invoice_date IS NULL 
								THEN DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.date_entered,121)) + 693596 
								ELSE DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.invoice_date,121)) + 693596
							END,
							CASE WHEN a.invoice_date IS NULL 
								THEN CONVERT(varchar(10), a.date_entered,121)
								ELSE CONVERT(varchar(10), a.invoice_date,121)
							END,
							CASE WHEN b.buying_group IS NULL THEN '' ELSE b.buying_group END
					FROM	orders_all a (NOLOCK)
					JOIN	cvo_orders_all b (NOLOCK)
					ON		a.order_no = b.order_no
					AND		a.ext = b.ext
					JOIN	#IncCust c
					ON		a.cust_code = c.child
				END

				-- v2.2 Start
				UPDATE	a
				SET		doc_date_int = c.doc_date_int,
						doc_date = CONVERT(varchar(10),DATEADD(day, c.doc_date_int - 693596, '1900-01-01'),121)  
				FROM	#bg_data a
				JOIN	artrxage b(NOLOCK)
				ON		a.customer_code = b.customer_code
				AND		a.doc_ctrl_num = b.doc_ctrl_num
				JOIN	#bg_data c
				ON		a.customer_code = b.customer_code	
				AND		b.apply_to_num = c.doc_ctrl_num
				WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')

				UPDATE	c
				SET		doc_date_int = a.date_doc,
						doc_date = CONVERT(varchar(10),DATEADD(day, a.date_doc - 693596, '1900-01-01'),121)  
				FROM	artrxage a (NOLOCK)
				JOIN	artrxage b (NOLOCK)
				ON		a.doc_ctrl_num = b.apply_to_num
				AND		a.customer_code = b.customer_code	
				JOIN	#bg_data c
				ON		b.customer_code = c.customer_code	
				AND		b.doc_ctrl_num = c.doc_ctrl_num
				WHERE	a.trx_type = 2031
				AND		b.trx_type = 2111
				AND		LEFT(b.trx_ctrl_num,2) = 'CB'
				-- v2.2 End

				UPDATE	a
				SET		parent = b.parent
				FROM	#bg_data a
				JOIN	#removed_child b
				ON		a.customer_code = b.customer_code
				WHERE	a.doc_date_int <= b.remove_date_int

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind3' ) 
					DROP INDEX #bg_data.#bg_data_ind3

				CREATE INDEX #bg_data_ind3 ON #bg_data (customer_code)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind4' ) 
					DROP INDEX #bg_data.#bg_data_ind4

				CREATE INDEX #bg_data_ind4 ON #bg_data (customer_code, doc_date_int)

				IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind5' ) 
					DROP INDEX #bg_data.#bg_data_ind5

				CREATE INDEX #bg_data_ind5 ON #bg_data (order_ctrl_num)

				UPDATE	a
				SET		parent = b.parent
				FROM	#bg_data a
				JOIN	#joined_child b
				ON		a.customer_code = b.customer_code
				WHERE	a.doc_date_int >= b.start_date_int

				UPDATE	#bg_data
				SET		parent = customer_code
				WHERE	customer_code = @customer_code

				SET @last_row_id = 0

				SELECT	TOP 1 @row_id = row_id
				FROM	#joinremove_child_distinct
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC

				WHILE (@@ROWCOUNT <> 0)
				BEGIN

					UPDATE	a
					SET		parent = b.parent
					FROM	#bg_data a
					JOIN	#joinremove_child_distinct b
					ON		a.customer_code = b.child
					WHERE	a.doc_date_int >= b.start_date_int
					AND		a.doc_date_int <= b.remove_date_int
					AND		b.row_id = @row_id				

					SET @last_row_id = @row_id

					SELECT	TOP 1 @row_id = row_id
					FROM	#joinremove_child_distinct
					WHERE	row_id > @last_row_id
					ORDER BY row_id ASC
				END

				UPDATE	a
				SET		parent = CASE WHEN ISNULL(b.buying_group,'') = '' THEN a.customer_code ELSE ISNULL(b.buying_group,'') END
				FROM	#bg_data a
				JOIN	#order_data b
				ON		a.order_ctrl_num = b.order_ctrl_num

				UPDATE	a
				SET		parent = b.parent
				FROM	#bg_data a
				JOIN	arnarel b (NOLOCK)
				ON		a.customer_code = b.child
				WHERE	a.parent = ''
				AND		b.parent = @customer_code

				DELETE	#bg_data
				WHERE	parent <> @customer_code

			END -- End of IsBG = 0
		END -- End of IsParent = 1
		ELSE
		BEGIN -- Start of IsParent = 0
			INSERT	#IncCust
			SELECT	@customer_code, @customer_code

			INSERT	#removed_child (parent, customer_code, remove_date_int, remove_date)
			SELECT	a.parent, a.child, a.end_date_int, a.end_date
			FROM	cvo_buying_groups_hist a (NOLOCK) 
			JOIN	#IncCust b
			ON		a.child = b.child
			WHERE	end_date_int IS NOT NULL

			INSERT	#joined_child (parent, customer_code, start_date_int, start_date)
			SELECT	a.parent, a.child, a.start_date_int, a.start_date
			FROM	cvo_buying_groups_hist a (NOLOCK) 
			JOIN	#IncCust b
			ON		a.child = b.child

			INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
			SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
					CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
			FROM	cvo_buying_groups_hist a (NOLOCK)
			JOIN	#joined_child b
			ON		a.parent = b.parent
			AND		a.child = b.customer_code
			JOIN	#removed_child c
			ON		a.parent = c.parent
			AND		a.child = c.customer_code		
			WHERE	a.start_date_int = b.start_date_int

			INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
			SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
					CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
			FROM	cvo_buying_groups_hist a (NOLOCK)
			JOIN	#removed_child b
			ON		a.parent = b.parent
			AND		a.child = b.customer_code
			JOIN	#joined_child c
			ON		a.parent = c.parent
			AND		a.child = c.customer_code		
			LEFT JOIN #joinremove_child d
			ON		a.parent = d.parent
			AND		a.child = d.child
			WHERE	a.end_date_int = b.remove_date_int
			AND		d.parent IS NULL
			AND		d.child IS NULL
			AND		d.start_date IS NULL

			INSERT	#joinremove_child_distinct (parent, child, start_date_int, start_date, remove_date_int, remove_date)
			SELECT	DISTINCT parent, child, start_date_int, start_date, remove_date_int, remove_date 
			FROM	#joinremove_child
			ORDER BY parent, child, start_date

			DROP TABLE #joinremove_child

			DELETE	a
			FROM	#removed_child a
			JOIN	#joinremove_child_distinct b
			ON		a.parent = b.parent
			AND		a.customer_code = b.child
			AND		a.remove_date_int = b.remove_date_int

			DELETE	a
			FROM	#joined_child a
			JOIN	#joinremove_child_distinct b
			ON		a.parent = b.parent
			AND		a.customer_code = b.child
			AND		a.start_date_int = b.start_date_int

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#removed_child' ) AND name = '#removed_child_ind2' ) 
				DROP INDEX #removed_child.#removed_child_ind2
			
			CREATE INDEX #removed_child_ind2 ON #removed_child (parent, customer_code)

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joined_child' ) AND name = '#joined_child_ind2' ) 
				DROP INDEX #joined_child.#joined_child_ind2

			CREATE INDEX #joined_child_ind2 ON #joined_child (parent, customer_code)

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joinremove_child_distinct' ) AND name = '#joinremove_child_distinct_ind2' ) 
				DROP INDEX #joinremove_child_distinct.#joinremove_child_distinct_ind2

			CREATE INDEX #joinremove_child_distinct_ind2 ON #joinremove_child_distinct (parent, child)

			IF (@type = 0)
			BEGIN
				INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
				SELECT	DISTINCT doc_ctrl_num,
						CASE WHEN trx_type IN (2031,2032,2161) THEN order_ctrl_num ELSE '' END, -- v1.1
						customer_code,
						date_doc,
						CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
						''
				FROM	artrxage a (NOLOCK)
				JOIN	#IncCust b
				ON		a.customer_code = b.child
				WHERE	a.trx_type NOT IN (2112,2113) -- v1.8


			END
			IF (@type = 1)
			BEGIN
				INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
				SELECT	DISTINCT trx_ctrl_num,
						CASE WHEN trx_type IN (2031,2032) THEN order_ctrl_num ELSE '' END,
						customer_code,
						date_doc,
						CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
						''
				FROM	arinpchg_all a (NOLOCK)
				JOIN	#IncCust b
				ON		a.customer_code = b.child

				INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
				SELECT	DISTINCT trx_ctrl_num,
						'',
						customer_code,
						date_doc,
						CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
						''
				FROM	arinppyt_all a (NOLOCK)
				JOIN	#IncCust b
				ON		a.customer_code = b.child

			END
			IF (@type = 2)
			BEGIN
				INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
				SELECT	DISTINCT 'SO',
						CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)),
						a.cust_code,
						CASE WHEN a.invoice_date IS NULL 
							THEN DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.date_entered,121)) + 693596 
							ELSE DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.invoice_date,121)) + 693596
						END,
						CASE WHEN a.invoice_date IS NULL 
							THEN CONVERT(varchar(10), a.date_entered,121)
							ELSE CONVERT(varchar(10), a.invoice_date,121)
						END,
						CASE WHEN b.buying_group IS NULL THEN '' ELSE b.buying_group END
				FROM	orders_all a (NOLOCK)
				JOIN	cvo_orders_all b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.ext
				JOIN	#IncCust c
				ON		a.cust_code = c.child
			END

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind7' ) 
				DROP INDEX #bg_data.#bg_data_ind7

			CREATE INDEX #bg_data_ind7 ON #bg_data (customer_code)

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind8' ) 
				DROP INDEX #bg_data.#bg_data_ind8

			CREATE INDEX #bg_data_ind8 ON #bg_data (customer_code, doc_date_int)

			IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind9' ) 
				DROP INDEX #bg_data.#bg_data_ind9

			CREATE INDEX #bg_data_ind9 ON #bg_data (order_ctrl_num)

			-- v2.2 Start
			UPDATE	a
			SET		doc_date_int = c.doc_date_int,
					doc_date = CONVERT(varchar(10),DATEADD(day, c.doc_date_int - 693596, '1900-01-01'),121)  
			FROM	#bg_data a
			JOIN	artrxage b(NOLOCK)
			ON		a.customer_code = b.customer_code
			AND		a.doc_ctrl_num = b.doc_ctrl_num
			JOIN	#bg_data c
			ON		a.customer_code = b.customer_code	
			AND		b.apply_to_num = c.doc_ctrl_num
			WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')

			UPDATE	c
			SET		doc_date_int = a.date_doc,
					doc_date = CONVERT(varchar(10),DATEADD(day, a.date_doc - 693596, '1900-01-01'),121)  
			FROM	artrxage a (NOLOCK)
			JOIN	artrxage b (NOLOCK)
			ON		a.doc_ctrl_num = b.apply_to_num
			AND		a.customer_code = b.customer_code	
			JOIN	#bg_data c
			ON		b.customer_code = c.customer_code	
			AND		b.doc_ctrl_num = c.doc_ctrl_num
			WHERE	a.trx_type = 2031
			AND		b.trx_type = 2111
			AND		LEFT(b.trx_ctrl_num,2) = 'CB'
			-- v2.2 End

			UPDATE	a
			SET		parent = b.parent
			FROM	#bg_data a
			JOIN	#removed_child b
			ON		a.customer_code = b.customer_code
			WHERE	a.doc_date_int <= b.remove_date_int

			UPDATE	a
			SET		parent = b.parent
			FROM	#bg_data a
			JOIN	#joined_child b
			ON		a.customer_code = b.customer_code
			WHERE	a.doc_date_int >= b.start_date_int

			SET @last_row_id = 0

			SELECT	TOP 1 @row_id = row_id
			FROM	#joinremove_child_distinct
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC

			WHILE (@@ROWCOUNT <> 0)
			BEGIN

				UPDATE	a
				SET		parent = b.parent
				FROM	#bg_data a
				JOIN	#joinremove_child_distinct b
				ON		a.customer_code = b.child
				WHERE	a.doc_date_int >= b.start_date_int
				AND		a.doc_date_int <= b.remove_date_int
				AND		b.row_id = @row_id				

				SET @last_row_id = @row_id

				SELECT	TOP 1 @row_id = row_id
				FROM	#joinremove_child_distinct
				WHERE	row_id > @last_row_id
				ORDER BY row_id ASC
			END

			UPDATE	a
			SET		parent = CASE WHEN ISNULL(b.buying_group,'') = '' THEN a.customer_code ELSE ISNULL(b.buying_group,'') END
			FROM	#bg_data a
			JOIN	#order_data b
			ON		a.order_ctrl_num = b.order_ctrl_num

			UPDATE	a
			SET		parent = b.parent
			FROM	#bg_data a
			JOIN	arnarel b (NOLOCK)
			ON		a.customer_code = b.child
			JOIN	arcust c (NOLOCK) -- v1.2
			ON		b.parent = c.customer_code -- v1.2
			WHERE	a.parent = ''
			AND		UPPER(c.addr_sort1) <> 'BUYING GROUP' -- v1.2

			UPDATE	#bg_data
			SET		parent = customer_code
			WHERE	parent = ''

			DELETE	#bg_data
			WHERE	parent <> customer_code

		END -- End of Isparent = 0
	END	-- End of customer code passed
	ELSE
	BEGIN -- Start of no customer passed in

		INSERT	#removed_child (parent, customer_code, remove_date_int, remove_date)
		SELECT	parent, child, end_date_int, end_date
		FROM	cvo_buying_groups_hist (NOLOCK) 
		WHERE	end_date_int IS NOT NULL

		INSERT	#joined_child (parent, customer_code, start_date_int, start_date)
		SELECT	parent, child, start_date_int, start_date
		FROM	cvo_buying_groups_hist (NOLOCK) 

		INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
		SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
				CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
		FROM	cvo_buying_groups_hist a (NOLOCK)
		JOIN	#joined_child b
		ON		a.parent = b.parent
		AND		a.child = b.customer_code
		JOIN	#removed_child c
		ON		a.parent = c.parent
		AND		a.child = c.customer_code		
		WHERE	a.start_date_int = b.start_date_int

		INSERT	#joinremove_child (parent, child, start_date_int, start_date, remove_date_int, remove_date)
		SELECT	a.parent, a.child, a.start_date_int, a.start_date, CASE WHEN a.end_date_int IS NULL THEN 803168 ELSE a.end_date_int END, 
				CASE WHEN a.end_date_int IS NULL THEN '2199-12-31' ELSE end_date END
		FROM	cvo_buying_groups_hist a (NOLOCK)
		JOIN	#removed_child b
		ON		a.parent = b.parent
		AND		a.child = b.customer_code
		JOIN	#joined_child c
		ON		a.parent = c.parent
		AND		a.child = c.customer_code		
		LEFT JOIN #joinremove_child d
		ON		a.parent = d.parent
		AND		a.child = d.child
		WHERE	a.end_date_int = b.remove_date_int
		AND		d.parent IS NULL
		AND		d.child IS NULL
		AND		d.start_date IS NULL

		INSERT	#joinremove_child_distinct (parent, child, start_date_int, start_date, remove_date_int, remove_date)
		SELECT	DISTINCT parent, child, start_date_int, start_date, remove_date_int, remove_date 
		FROM	#joinremove_child
		ORDER BY parent, child, start_date

		DROP TABLE #joinremove_child

		DELETE	a
		FROM	#removed_child a
		JOIN	#joinremove_child_distinct b
		ON		a.parent = b.parent
		AND		a.customer_code = b.child
		AND		a.remove_date_int = b.remove_date_int

		DELETE	a
		FROM	#joined_child a
		JOIN	#joinremove_child_distinct b
		ON		a.parent = b.parent
		AND		a.customer_code = b.child
		AND		a.start_date_int = b.start_date_int

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#removed_child' ) AND name = '#removed_child_ind10' ) 
			DROP INDEX #removed_child.#removed_child_ind10

		CREATE INDEX #removed_child_ind10 ON #removed_child (parent, customer_code)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joined_child' ) AND name = '#joined_child_ind11' ) 
			DROP INDEX #joined_child.#joined_child_ind11

		CREATE INDEX #joined_child_ind11 ON #joined_child (parent, customer_code)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joined_child' ) AND name = '#joined_child_ind31' ) 
			DROP INDEX #joined_child.#joined_child_ind31

		CREATE INDEX #joined_child_ind31 ON #joined_child (customer_code, start_date_int)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#joinremove_child_distinct' ) AND name = '#joinremove_child_distinct_ind12' ) 
			DROP INDEX #joinremove_child_distinct.#joinremove_child_distinct_ind12

		CREATE INDEX #joinremove_child_distinct_ind12 ON #joinremove_child_distinct (parent, child)


		IF (@stm_type = 'BG')
		BEGIN
			INSERT	#IncCust
			SELECT	DISTINCT parent, parent 
			FROM	cvo_buying_groups_hist (NOLOCK)

			INSERT	#IncCust
			SELECT	DISTINCT child, child 
			FROM	cvo_buying_groups_hist (NOLOCK)

		END
		IF (@stm_type = 'NA')
		BEGIN
			INSERT	#IncCust
			SELECT	DISTINCT a.parent, a.parent
			FROM	arnarel a (NOLOCK)
			JOIN	arcust b (NOLOCK)
			ON		a.parent = b.customer_code
			WHERE	UPPER(b.addr_sort1) <> 'BUYING GROUP'
			AND		b.country_code = 'US'

			INSERT	#IncCust
			SELECT	DISTINCT a.child, a.child 
			FROM	arnarel a (NOLOCK)
			JOIN	arcust b (NOLOCK)
			ON		a.parent = b.customer_code
			WHERE	UPPER(b.addr_sort1) <> 'BUYING GROUP'
			AND		b.country_code = 'US'

		END
		IF (@stm_type = 'CUS')
		BEGIN
			INSERT	#IncCust
			SELECT	a.customer_code, a.customer_code
			FROM	arcust a (NOLOCK)
			LEFT JOIN arnarel b (NOLOCK)
			ON		a.customer_code = b.child
			LEFT JOIN arnarel c (NOLOCK)
			ON		a.customer_code = c.parent
			WHERE	b.child IS NULL
			AND		c.parent IS NULL
			AND		a.country_code = 'US'

			-- v1.2 Start
			INSERT	#IncCust
			SELECT	a.cust_code, a.cust_code
			FROM	#order_data a
			JOIN	arcust b (NOLOCK)
			ON		a.cust_code = b.customer_code
			LEFT JOIN #IncCust c (NOLOCK)
			ON		a.cust_code = c.parent
			WHERE	c.parent IS NULL
			AND		b.country_code = 'US'
			AND		ISNULL(a.buying_group,'') = ''
			-- v1.2 End

			-- v1.3 Start
			INSERT	#IncCust
			SELECT	a.customer_code, a.customer_code
			FROM	#joined_child a
			LEFT JOIN #IncCust c (NOLOCK)
			ON		a.customer_code = c.parent
			WHERE	c.parent IS NULL

			INSERT	#IncCust
			SELECT	a.customer_code, a.customer_code
			FROM	#removed_child a
			LEFT JOIN #IncCust c (NOLOCK)
			ON		a.customer_code = c.parent
			WHERE	c.parent IS NULL
			-- v1.3
		END
		IF (@stm_type = 'INT')
		BEGIN
			INSERT	#IncCust
			SELECT	customer_code, customer_code
			FROM	arcust (NOLOCK)
			WHERE	country_code <> 'US'
		END
			
		IF (@stm_type = '')
		BEGIN
			INSERT	#IncCust
			SELECT	DISTINCT parent, parent 
			FROM	cvo_buying_groups_hist (NOLOCK)

			INSERT	#IncCust
			SELECT	DISTINCT child, child 
			FROM	cvo_buying_groups_hist (NOLOCK)

			INSERT	#IncCust
			SELECT	DISTINCT a.parent, a.parent
			FROM	arnarel a (NOLOCK)
			JOIN	arcust b (NOLOCK)
			ON		a.parent = b.customer_code
			LEFT JOIN #IncCust c
			ON		a.parent = c.parent
			WHERE	UPPER(b.addr_sort1) <> 'BUYING GROUP'
			AND		b.country_code = 'US'
			AND		c.parent IS NULL

			INSERT	#IncCust
			SELECT	DISTINCT a.child, a.child 
			FROM	arnarel a (NOLOCK)
			JOIN	arcust b (NOLOCK)
			ON		a.parent = b.customer_code
			LEFT JOIN #IncCust c
			ON		a.child = c.parent
			WHERE	UPPER(b.addr_sort1) <> 'BUYING GROUP'
			AND		b.country_code = 'US'
			AND		c.parent IS NULL

			INSERT	#IncCust
			SELECT	a.customer_code, a.customer_code
			FROM	arcust a (NOLOCK)
			LEFT JOIN arnarel b (NOLOCK)
			ON		a.customer_code = b.child
			LEFT JOIN arnarel c (NOLOCK)
			ON		a.customer_code = c.parent
			LEFT JOIN #IncCust d
			ON		a.customer_code = d.parent
			WHERE	b.child IS NULL
			AND		c.parent IS NULL
			AND		a.country_code = 'US'
			AND		d.parent IS NULL

			INSERT	#IncCust
			SELECT	a.customer_code, a.customer_code
			FROM	arcust a (NOLOCK)
			LEFT JOIN #IncCust b
			ON		a.customer_code = b.parent
			WHERE	a.country_code <> 'US'
			AND		b.parent IS NULL
		END

		-- v1.9 Start		
		IF (@stm_range > '')
		BEGIN
			IF (@stm_type IN ('CUS','INT'))
			BEGIN
				IF (charindex('a.customer_code',@stm_range) > 0)
				BEGIN
					SELECT @SQL = "DELETE FROM #IncCust WHERE child NOT IN (SELECT child FROM #IncCust a WHERE " + 
						SUBSTRING(@stm_range,charindex('a.customer_code',@stm_range),charindex(') )',@stm_range,charindex('a.customer_code',@stm_range)) - charindex('a.customer_code',@stm_range)) + ")"
					SET @SQL = REPLACE(@SQL, 'customer_code' , 'child' )
				
					EXEC(@SQL)
				END
			END
		END
		-- v1.9

		IF (@type = 0)
		BEGIN
			INSERT	#bg_data_detail (doc_ctrl_num, order_ctrl_num, apply_to_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT doc_ctrl_num,
					order_ctrl_num, 
					apply_to_num,
					customer_code,
					date_doc,
					CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
					''
			FROM	artrxage a (NOLOCK)
			JOIN	#IncCust b
			ON		a.customer_code = b.parent

		END
		IF (@type = 1)
		BEGIN
			INSERT	#bg_data_detail (doc_ctrl_num, order_ctrl_num, apply_to_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT trx_ctrl_num,
					CASE WHEN trx_type IN (2031,2032) THEN order_ctrl_num ELSE '' END,
					'',
					customer_code,
					date_doc,
					CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
					''
			FROM	arinpchg_all a (NOLOCK)
			JOIN	#IncCust b
			ON		a.customer_code = b.parent

			INSERT	#bg_data_detail (doc_ctrl_num, order_ctrl_num, apply_to_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT trx_ctrl_num,
					'',
					'',
					customer_code,
					date_doc,
					CONVERT(varchar(10),DATEADD(DAY, date_doc - 693596, '1900-01-01'),121),
					''
			FROM	arinppyt_all a (NOLOCK)
			JOIN	#IncCust b
			ON		a.customer_code = b.parent

		END
		IF (@type = 2)
		BEGIN
			INSERT	#bg_data_detail (doc_ctrl_num, order_ctrl_num, apply_to_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT 'SO',
					CAST(a.order_no AS varchar(10)) + '-' + CAST(a.ext AS varchar(6)),
					'',
					a.cust_code,
					CASE WHEN a.invoice_date IS NULL 
						THEN DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.date_entered,121)) + 693596 
						ELSE DATEDIFF(DAY, '1900-01-01', CONVERT(varchar(10), a.invoice_date,121)) + 693596
					END,
					CASE WHEN a.invoice_date IS NULL 
						THEN CONVERT(varchar(10), a.date_entered,121)
						ELSE CONVERT(varchar(10), a.invoice_date,121)
					END,
					CASE WHEN b.buying_group IS NULL THEN '' ELSE b.buying_group END
			FROM	orders_all a (NOLOCK)
			JOIN	cvo_orders_all b (NOLOCK)
			ON		a.order_no = b.order_no
			AND		a.ext = b.ext
			JOIN	#IncCust b
			ON		a.cust_code = b.parent
		END

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data_detail' ) AND name = '#bg_data_ind10' ) 
			DROP INDEX #bg_data_detail.#bg_data_ind10

		CREATE INDEX #bg_data_ind10 ON #bg_data_detail (customer_code)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data_detail' ) AND name = '#bg_data_ind11' ) 
			DROP INDEX #bg_data_detail.#bg_data_ind11

		CREATE INDEX #bg_data_ind11 ON #bg_data_detail (customer_code, doc_date_int)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data_detail' ) AND name = '#bg_data_ind12' ) 
			DROP INDEX #bg_data_detail.#bg_data_ind12

		CREATE INDEX #bg_data_ind12 ON #bg_data_detail (order_ctrl_num)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data_detail' ) AND name = '#bg_data_ind13' ) 
			DROP INDEX #bg_data_detail.#bg_data_ind13

		CREATE INDEX #bg_data_ind13 ON #bg_data_detail (doc_ctrl_num, customer_code)

		-- v2.2 Start
		UPDATE	a
		SET		doc_date_int = c.doc_date_int,
				doc_date = CONVERT(varchar(10),DATEADD(day, c.doc_date_int - 693596, '1900-01-01'),121)  
		FROM	#bg_data_detail a
		JOIN	artrxage b(NOLOCK)
		ON		a.customer_code = b.customer_code
		AND		a.doc_ctrl_num = b.doc_ctrl_num
		JOIN	#bg_data_detail c
		ON		a.customer_code = b.customer_code	
		AND		b.apply_to_num = c.doc_ctrl_num
		WHERE	(LEFT(a.doc_ctrl_num,3) = 'FIN' OR LEFT(a.doc_ctrl_num,4) = 'LATE')

		UPDATE	c
		SET		doc_date_int = a.date_doc,
				doc_date = CONVERT(varchar(10),DATEADD(day, a.date_doc - 693596, '1900-01-01'),121)  
		FROM	artrxage a (NOLOCK)
		JOIN	artrxage b (NOLOCK)
		ON		a.doc_ctrl_num = b.apply_to_num
		AND		a.customer_code = b.customer_code	
		JOIN	#bg_data_detail c
		ON		b.customer_code = c.customer_code	
		AND		b.doc_ctrl_num = c.doc_ctrl_num
		WHERE	a.trx_type = 2031
		AND		b.trx_type = 2111
		AND		LEFT(b.trx_ctrl_num,2) = 'CB'
		-- v2.2 End

		UPDATE	a
		SET		parent = b.parent
		FROM	#bg_data_detail a
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.doc_date_int <= b.remove_date_int

		UPDATE	a
		SET		parent = b.customer_code
		FROM	#bg_data_detail a
		JOIN	#removed_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.doc_date_int > b.remove_date_int

		UPDATE	a
		SET		parent = b.parent
		FROM	#bg_data_detail a
		JOIN	#joined_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.doc_date_int >= b.start_date_int

		UPDATE	a
		SET		parent = b.customer_code
		FROM	#bg_data_detail a
		JOIN	#joined_child b
		ON		a.customer_code = b.customer_code
		WHERE	a.doc_date_int < b.start_date_int

		UPDATE	a
		SET		parent = b.parent
		FROM	#bg_data_detail a
		JOIN	artierrl b (NOLOCK)
		ON		a.customer_code = b.parent
		AND		b.tier_level = 1
		AND		relation_code = @relation_code
	
		SET @last_row_id = 0

		SELECT	TOP 1 @row_id = row_id
		FROM	#joinremove_child_distinct
		WHERE	row_id > @last_row_id
		ORDER BY row_id ASC

		WHILE (@@ROWCOUNT <> 0)
		BEGIN

			UPDATE	a
			SET		parent = b.parent
			FROM	#bg_data_detail a
			JOIN	#joinremove_child_distinct b
			ON		a.customer_code = b.child
			WHERE	a.doc_date_int >= b.start_date_int
			AND		a.doc_date_int <= b.remove_date_int
			AND		b.row_id = @row_id				

			SET @last_row_id = @row_id

			SELECT	TOP 1 @row_id = row_id
			FROM	#joinremove_child_distinct
			WHERE	row_id > @last_row_id
			ORDER BY row_id ASC
		END

		UPDATE	a
		SET		parent = CASE WHEN ISNULL(b.buying_group,'') = '' THEN a.customer_code ELSE ISNULL(b.buying_group,'') END
		FROM	#bg_data_detail a
		JOIN	#order_data b
		ON		a.order_ctrl_num = b.order_ctrl_num

		UPDATE	a
		SET		parent = b.parent
		FROM	#bg_data_detail a
		JOIN	arnarel b (NOLOCK)
		ON		a.customer_code = b.child
		JOIN	arcust c (NOLOCK) -- v1.1
		ON		b.parent = c.customer_code -- v1.1
		WHERE	a.parent = ''		
		AND		UPPER(c.addr_sort1) <> 'BUYING GROUP' -- v1.1

		UPDATE	a
		SET		parent = c.parent
		FROM	#bg_data_detail a
		JOIN	#bg_data_detail c
		ON		a.doc_ctrl_num = c.apply_to_num
		AND		a.customer_code = c.customer_code
		WHERE	a.doc_ctrl_num <> c.apply_to_num
		
		-- v1.4 End

		INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
		SELECT	doc_ctrl_num, apply_to_num, customer_code, doc_date_int, doc_date, parent
		FROM	#bg_data_detail

		DROP TABLE #bg_data_detail

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind33' ) 
			DROP INDEX #bg_data.#bg_data_ind33

		CREATE INDEX #bg_data_ind33 ON #bg_data (parent)

		IF (@stm_type = 'BG')
		BEGIN
			DELETE	FROM #bg_data 
			WHERE	parent NOT IN (SELECT parent FROM cvo_buying_groups_hist (NOLOCK))
			
		END

		IF (@stm_type = 'CUS') -- v1.7a
		BEGIN
			DELETE	FROM #bg_data 
			WHERE	parent IN (SELECT parent FROM arnarel (NOLOCK))
			
		END


		-- v1.9 Start
		IF (@stm_range > '')
		BEGIN
			IF (@stm_type IN ('BG','NA'))
			BEGIN
				IF (charindex('n.parent',@stm_range) > 0)
				BEGIN 
					SELECT @SQL = "DELETE FROM #IncCust WHERE parent NOT IN (SELECT parent FROM #IncCust n WHERE " + 
						SUBSTRING(@stm_range,charindex('n.parent',@stm_range),charindex(') )',@stm_range,charindex('n.parent',@stm_range)) - charindex('n.parent',@stm_range)) + ")"
				
					EXEC(@SQL)
				END
			END
		END
		-- v1.9 End

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind20' ) 
			DROP INDEX #bg_data.#bg_data_ind20

		CREATE INDEX #bg_data_ind20 ON #bg_data (customer_code)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind21' ) 
			DROP INDEX #bg_data.#bg_data_ind21

		CREATE INDEX #bg_data_ind21 ON #bg_data (customer_code, doc_date_int)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind22' ) 
			DROP INDEX #bg_data.#bg_data_ind22

		CREATE INDEX #bg_data_ind22 ON #bg_data (order_ctrl_num)

		IF EXISTS( SELECT 1 FROM tempdb..sysindexes WHERE id = OBJECT_ID( 'tempdb..#bg_data' ) AND name = '#bg_data_ind23' ) 
			DROP INDEX #bg_data.#bg_data_ind23

		CREATE INDEX #bg_data_ind23 ON #bg_data (doc_ctrl_num, customer_code)


	END	-- End of no customer passed in

	UPDATE	#bg_data
	SET		parent = customer_code
	WHERE	parent = ''

	IF (ISNULL(@customer_code,'') <> '' AND @type <> 2) -- v1.7
	BEGIN

		CREATE TABLE #bg_data2 (
			doc_ctrl_num	varchar(16),
			order_ctrl_num	varchar(16),
			customer_code	varchar(10),
			doc_date_int	int,
			doc_date		varchar(10),
			parent			varchar(10))

			INSERT	#bg_data2 (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT doc_ctrl_num, '', customer_code, MIN(doc_date_int), MIN(doc_date), parent
			FROM	#bg_data
			GROUP BY doc_ctrl_num, customer_code, parent

			TRUNCATE TABLE #bg_data

			INSERT	#bg_data (doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent)
			SELECT	DISTINCT doc_ctrl_num, order_ctrl_num, customer_code, doc_date_int, doc_date, parent
			FROM	#bg_data2		  

			DROP TABLE #bg_data2

		END

END

GO
GRANT EXECUTE ON  [dbo].[cvo_bg_get_document_data_sp] TO [public]
GO
