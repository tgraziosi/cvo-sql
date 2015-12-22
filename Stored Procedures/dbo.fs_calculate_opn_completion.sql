SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO




-- SKN 12/10/99 Change to correctly handle setup time.
CREATE PROCEDURE [dbo].[fs_calculate_opn_completion]
	(
	@sched_id		INT,
	@prod_no		INT		= NULL,
	@prod_ext		INT		= NULL,
        @compare_schedule_ind	INT		= 0,
        @qc_no                  INT             = 0
	)
AS
BEGIN







DECLARE	@prod_completed_qty FLOAT,
        @prod_compl_was_reported INT,
        @op_compl_was_reported INT,
	@op_completed_qty FLOAT,
	@plan_pcs FLOAT,
	@pieces FLOAT,
	@direction INT,
	@p_qty FLOAT,
	@resource_run_time FLOAT,
	@seq_no CHAR(8),	-- rev 1
        @pool_qty FLOAT,
        @op_num INT,
        @p_pcs FLOAT

	SELECT @prod_completed_qty = 0.0
        SELECT @prod_compl_was_reported = 0
        SELECT @op_compl_was_reported = 0

        SELECT @op_completed_qty = 0.0
        SELECT @op_num = 0
  
        -- Select all prod_list rows for the production.  Order them by direction descending and line_no descending.
if @compare_schedule_ind = 1
begin
	DECLARE c_prod_list CURSOR FOR
	SELECT	plan_pcs,   
		pieces,
		direction,
		p_qty,
		seq_no,	-- rev 1
		p_pcs
  		FROM #process_detail  
		WHERE (prod_no = @prod_no) AND (prod_ext = @prod_ext) and (d_qc_no = @qc_no)	-- mls 9/10/03 SCR 31868
		  ORDER BY direction DESC, p_line, seq_no, line_no
end
else
begin
	DECLARE c_prod_list CURSOR FOR
	SELECT	dbo.prod_list.plan_pcs,   
		dbo.prod_list.pieces,
		dbo.prod_list.direction,
		dbo.prod_list.p_qty,
		dbo.prod_list.seq_no,	-- rev 1
		dbo.prod_list.p_pcs
  		FROM dbo.prod_list  
		WHERE (dbo.prod_list.prod_no = @prod_no) AND (dbo.prod_list.prod_ext = @prod_ext) and qc_no = @qc_no
                  and status != 'S'
                  order by direction desc, p_line, seq_no, line_no
end
 
	OPEN c_prod_list

	FETCH c_prod_list INTO @plan_pcs, @pieces, @direction, @p_qty, @seq_no, @p_pcs


        WHILE @@Fetch_Status = 0
            BEGIN
	        if @p_pcs = 0
                   SELECT @p_pcs = 1
                -- Direction = 1 means this line reports pieces completed for the production.  Subtract to get the remaining qty.
		if @direction = 1
                    BEGIN
                    if (@seq_no = '') AND (@pieces > 0.0)	-- rev 1
			BEGIN
			    SELECT @prod_completed_qty = @pieces
                            -- Below is just a boolean so I know 
                            SELECT @prod_compl_was_reported = 1
		        END
                     END
		 ELSE
		     BEGIN
   		     if @plan_pcs > 0
                           -- plan_pcs > 0 means this is the last line for the operation.  If completion was reported 
                           -- it will be here.  Use this information to compute the remaining
                           -- pieces to be completed at this operation.
                           BEGIN
                                SELECT @op_compl_was_reported = 0
                                SELECT @op_completed_qty = @prod_completed_qty * @p_pcs
                                SELECT @op_num = @op_num + 1
                                if @pieces > 0
				    BEGIN
                                        SELECT @op_compl_was_reported = 1
					SELECT @op_completed_qty = @pieces
                                        -- If the quantity completed at this operation
                                        -- is less than the quantity reported as complete at the production
                                        -- level, set the operation completed quantity = the
                                        -- production completed quantity.
					if (@op_completed_qty < (@prod_completed_qty * @p_pcs)) and (@prod_compl_was_reported = 1)
                                            BEGIN
					        SELECT @op_completed_qty = (@prod_completed_qty * @p_pcs)
                                            END
	    			    END
                                
                                 if (@prod_compl_was_reported = 1) OR (@op_compl_was_reported = 1)
           	                    BEGIN
					UPDATE dbo.sched_operation  
					SET complete_qty = @op_completed_qty,
					   
					   -- assume that setup time is zero	
					   ave_flat_time = (case when (dbo.sched_operation.ave_unit_time  > 0)
						then 0 else dbo.sched_operation.ave_flat_time end)
					   
					 FROM sched_operation, sched_process 
					 WHERE dbo.sched_process.sched_process_id = dbo.sched_operation.sched_process_id
					 AND dbo.sched_process.prod_no = @prod_no 
					 and dbo.sched_process.prod_ext = @prod_ext
                                         and isnull(dbo.sched_process.qc_no,0) = @qc_no
					 and dbo.sched_operation.operation_step = @op_num
                                    END
                            END
              END -- end of if direction = 1

	FETCH c_prod_list INTO @plan_pcs, @pieces, @direction, @p_qty, @seq_no, @p_pcs
	END -- end of while loop

        -- Check to see if anything needs to be updated for the last (first) operation.
   

CLOSE c_prod_list

DEALLOCATE c_prod_list
 
RETURN
END
GO
GRANT EXECUTE ON  [dbo].[fs_calculate_opn_completion] TO [public]
GO
