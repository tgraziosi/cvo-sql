CREATE TABLE [dbo].[cc_cust_status_hist]
(
[customer_code] [varchar] (8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[status_code] [varchar] (5) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
[date] [int] NOT NULL,
[user_id] [smallint] NOT NULL,
[clear_date] [int] NULL,
[cleared_by] [smallint] NULL,
[sequence_num] [smallint] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*    
Object:      Trigger  [CVO_CC_cust_hold_tr]      
Source file: CVO_CC_cust_hold_tr.sql    
Author: Bruce Bishop     
Created:  09/22/2011    
Called by:  ,     
Copyright:   Epicor Software 2011.  All rights reserved.      
*/    
-- v1.1 CB 15/11/2011 - Should not update orders on credit hold and orders which are picked  
-- v1.2 CB 05/11/2012 - Issue #891 - WMS Transaction Log 
-- v1.3 CB 23/07/2013 - Issue #927 - Buying Group Switching
-- v1.4 CB 07/11/2013 - Issue #1359 - User and credit Holds do not soft allocate if the hold reason is not in cvo_alloc_hold_values_tbl 
-- v1.5 CB 28/10/2016 - #1616 Hold Processing
    
CREATE TRIGGER [dbo].[CVO_CC_cust_hold_tr] ON [dbo].[cc_cust_status_hist]   
FOR INSERT, UPDATE  
AS     
BEGIN    
	-- DIRECTIVES
	SET NOCOUNT ON

	-- DECLARATIONS
	DECLARE	@sequence_id		int,     
			@max_sequence_id	int,    
			@customer_code		varchar(8),    
			@status_code		varchar(5),    
			@clear_date			int,     
			@sequence_num		smallint,    
			@fin_sequence_id	int,     
			@fin_max_sequence_id int,    
			@customer_code_up	varchar(8),    
			@prior_hold			varchar(10)    
    
	-- create table for status    
	CREATE TABLE #hold (    
		ID				int identity(1,1),    
		customer_code	varchar (8)null,    
		status_code		varchar (5)null,    
		date			int null,    
		user_id			smallint null,    
		clear_date		int null,    
		cleared_by		smallint null,    
		sequence_num	smallint null)    

	CREATE INDEX idx_customer_code ON #hold (customer_code) WITH FILLFACTOR = 80    
	CREATE INDEX idx_sequence_num ON #hold (sequence_num) WITH FILLFACTOR = 80      
    
	CREATE TABLE #cust (    
		ID				int identity(1,1),    
		customer_code	varchar (8)null,    
		sequence_num	smallint null)    

	CREATE INDEX idx_customer_code ON #cust (customer_code) WITH FILLFACTOR = 80    
	CREATE INDEX idx_sequence_num ON #cust (sequence_num) WITH FILLFACTOR = 80    
    
	-- v1.5 Start
	CREATE TABLE #next_holds (
		order_no	int,
		order_ext	int,
		hold_reason	varchar(10))
	-- v1.5

	INSERT	#hold (customer_code, status_code, date, user_id, clear_date, cleared_by, sequence_num)    
	SELECT	customer_code,    
			status_code,    
			date,    
			user_id,    
			clear_date,    
			cleared_by,    
			sequence_num    
	FROM	inserted (NOLOCK)     
	WHERE	status_code IN (SELECT hold_code FROM adm_oehold (NOLOCK)) -- TM    
    
	SELECT	@sequence_id = 0, 
			@max_sequence_id = 0    

	SELECT	@sequence_id = MIN(ID), 
			@max_sequence_id = MAX(ID)     
	FROM	#hold (NOLOCK)    
    
	WHILE (@sequence_id <= @max_sequence_id )      
	BEGIN    
    
		SELECT	@customer_code = NULL,    
				@status_code = NULL,    
				@clear_date = NULL,    
				@sequence_num = NULL    
    
		SELECT  @customer_code = customer_code,    
				@status_code = status_code,    
				@clear_date = clear_date,    
				@sequence_num = sequence_num    
		FROM	#hold (NOLOCK)    
		WHERE	ID = @sequence_id    
    
		-- put orders on hold    
		TRUNCATE TABLE #cust    
    
		INSERT #cust (customer_code, sequence_num)    
		SELECT @customer_code, @sequence_num    

		-- v1.3 Start    
		-- insert #cust (customer_code, sequence_num)    
		-- select child, @sequence_num from arnarel (nolock) where parent = @customer_code    

		INSERT	#cust (customer_code, sequence_num)    
		SELECT	child, @sequence_num
		FROM	dbo.f_cvo_get_buying_group_child_list(@customer_code,CONVERT(varchar(10),GETDATE(),121))
 
		-- v1.2    
		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
		SELECT	@fin_sequence_id = '',     
				@fin_max_sequence_id = '',     
				@customer_code_up = ''    
    
		SELECT	@fin_sequence_id = MIN(ID), 
				@fin_max_sequence_id = MAX(ID)     
		FROM	#cust (NOLOCK)    
    
        WHILE (@fin_sequence_id <= @fin_max_sequence_id )      
		BEGIN    
       
			IF (@clear_date IS NULL)    
			BEGIN    
				SELECT	@customer_code_up = customer_code    
				FROM	#cust (NOLOCK)     
				where	ID = @fin_sequence_id    

				-- v1.5 Start
				-- Setting C&C Hold    
				INSERT	cvo_so_holds
				SELECT	order_no, ext, ISNULL(hold_reason,''),
						dbo.f_get_hold_priority(ISNULL(hold_reason,''),''),
						SUSER_NAME(),
						GETDATE()
				FROM	orders_all (NOLOCK)
				WHERE	cust_code = @customer_code_up    
				AND		status < 'P'  
				AND		status <> 'C' -- v1.1 
				AND		ISNULL(hold_reason,'') > ''				

				--UPDATE	CVO_orders_all    
				--SET		prior_hold = isnull(hold_reason, '')     
				--FROM	orders_all     
				--WHERE	CVO_orders_all.order_no = orders_all.order_no    
				--AND		CVO_orders_all.ext = orders_all.ext    
				--AND		orders_all.cust_code = @customer_code_up    
				--AND		orders_all.status < 'P'  
				--AND		orders_all.status <> 'C' -- v1.1  
				-- v1.5 End

				UPDATE	orders_all WITH (ROWLOCK)    
				SET		status = 'A',     
						hold_reason = @status_code     
				WHERE	cust_code = @customer_code_up    
				AND		status < 'P'    
				AND		status <> 'C' -- v1.1  

				-- v1.2 Start
				INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
				SELECT	GETDATE() , suser_name() , 'BO' , 'C&C UPDATE' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
						'STATUS:A/USER HOLD; HOLD REASON:' + LTRIM(RTRIM(@status_code)) + ' - ACCOUNTING'
				FROM	orders_all a (NOLOCK)
				JOIN	cvo_orders_all b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.ext
				WHERE	cust_code = @customer_code_up    
				AND		status = 'A'
				AND		hold_reason = @status_code
				-- v1.2 End

				EXEC dbo.cvo_release_to_soft_alloc_sp @customer_code_up, 1 -- v1.4

			END -- if @clear_date is null    
    
			IF (@clear_date IS NOT NULL)    
			BEGIN    
				SELECT	@customer_code_up = customer_code    
				FROM	#cust (NOLOCK)     
				WHERE	ID = @fin_sequence_id    
    
				-- v1.5 Start
				TRUNCATE TABLE #next_holds

				INSERT	#next_holds (order_no, order_ext, hold_reason)
				SELECT	a.order_no,
						a.ext,
						ISNULL(b.hold_reason,'')
				FROM	orders_all a (NOLOCK)
				LEFT JOIN cvo_next_so_hold_vw b (NOLOCK)
				ON		a.order_no = b.order_no
				AND		a.ext = b.order_ext
				WHERE	a.status < 'P'
				AND		a.status NOT IN ('N','C')
				AND		a.hold_reason IN (SELECT status_code FROM cc_status_codes (NOLOCK))
				AND		a.cust_code = @customer_code_up
							
				UPDATE	a
				SET		status = CASE WHEN b.hold_reason = '' THEN 'N'
								 WHEN b.hold_reason IN ('PD','CL') THEN 'C'
								 ELSE 'A' END,
						hold_reason = b.hold_reason
				FROM	orders_all a
				JOIN	#next_holds b				
				ON		a.order_no = b.order_no
				AND		a.ext = b.order_ext

				DELETE  a
				FROM	cvo_so_holds a
				JOIN	#next_holds b
				ON		a.order_no = b.order_no
				AND		a.order_ext = b.order_ext
				AND		a.hold_reason = b.hold_reason

--				UPDATE	orders_all    
--				SET		status = CASE WHEN (prior_hold is not null) and (prior_hold <> '') THEN 'A' ELSE 'N' END,    
--						hold_reason = isnull(prior_hold,'')    
--				FROM	CVO_orders_all     
--				WHERE	CVO_orders_all.order_no = orders_all.order_no    
--				AND		CVO_orders_all.ext = orders_all.ext    
--				AND		orders_all.cust_code = @customer_code_up    
--				AND		orders_all.status < 'P'    
--				AND		orders_all.status not in  ('N','C') -- v1.1 Add credit hold    
--				AND		orders_all.hold_reason in (SELECT status_code FROM cc_status_codes)    -- TM    

				-- v1.2 Start
				INSERT INTO tdc_log ( tran_date , userid , trans_source , module , trans , tran_no , tran_ext , part_no , lot_ser , bin_no , location , quantity , data ) 
				SELECT	GETDATE() , suser_name() , 'BO' , 'C&C UPDATE' , 'ORDER UPDATE' , a.order_no , a.ext , '' , '' , '' , a.location , '' ,
						'STATUS:' + CASE WHEN b.hold_reason <> '' THEN 'A/PROMOTE USER HOLD; HOLD REASON:' + LTRIM(RTRIM(isnull(b.hold_reason,''))) ELSE 'N/RELEASE USER HOLD - ACCOUNTING' END   
				FROM	orders_all a (NOLOCK)
				JOIN	#next_holds b
				ON		a.order_no = b.order_no
				AND		a.ext = b.order_ext

--				JOIN	cvo_orders_all b (NOLOCK)
--				ON		a.order_no = b.order_no
--				AND		a.ext = b.ext
--				WHERE	a.cust_code = @customer_code_up    
--				AND		a.status < 'P'    
--				AND		a.status not in  ('C') -- v1.1 Add credit hold    
--				AND		a.hold_reason in (select status_code from cc_status_codes) 
				-- v1.2 End

--				UPDATE	CVO_orders_all 
--				SET		prior_hold = NULL    
--				FROM	dbo.CVO_orders_all c 
--				JOIN	orders_all o    
--				ON		o.order_no = c.order_no 
--				AND		o.ext = c.ext     
--				WHERE	o.cust_code = @customer_code_up    
--				AND		status <'P'     
--				AND		status <> 'C' -- v1.1  
				-- v1.5 End
       
				EXEC dbo.cvo_release_to_soft_alloc_sp @customer_code_up -- v1.4
			END -- if @clear_date is not null    
       
			SELECT @fin_sequence_id = @fin_sequence_id + 1    
		END     
    
		--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
    
		SELECT @sequence_id = @sequence_id +1    
	END    
   
    DROP TABLE #cust    
	DROP TABLE #hold    
	DROP TABLE #next_holds -- v1.5
END
GO
CREATE NONCLUSTERED INDEX [cc_cust_status_hist_idx2] ON [dbo].[cc_cust_status_hist] ([clear_date]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [cc_cust_status_hist_idx] ON [dbo].[cc_cust_status_hist] ([customer_code], [status_code], [date], [sequence_num]) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT SELECT ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT INSERT ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT DELETE ON  [dbo].[cc_cust_status_hist] TO [public]
GO
GRANT UPDATE ON  [dbo].[cc_cust_status_hist] TO [public]
GO
