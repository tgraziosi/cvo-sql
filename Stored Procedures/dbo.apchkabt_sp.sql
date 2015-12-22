SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[apchkabt_sp] @process_group_num varchar(16), 
						@cash_acct_code varchar(32),
						@trx_type 		 smallint,
						@debug_level 	 smallint = 0
AS

 IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apchkabt.sp" + ", line " + STR( 37, 5 ) + " -- ENTRY: "


 IF ((@trx_type = 4996) OR (@trx_type = 4994))
	 BEGIN
		 BEGIN TRAN ABORT
 
		 

		 DELETE apvchdr
		 WHERE process_ctrl_num = @process_group_num
		 AND state_flag = -1

		 

		 DELETE apchkstb
		 FROM #check_header, apchkstb
		 WHERE apchkstb.payment_num = #check_header.trx_ctrl_num
		 AND apchkstb.posted_flag = -1



		 

		 DELETE apexpdst
		 FROM #check_header, apexpdst
		 WHERE apexpdst.payment_num = #check_header.trx_ctrl_num
		 AND apexpdst.posted_flag = -1

		 

		 UPDATE apinppyt
		 SET doc_ctrl_num = "",
		 printed_flag = 0,
			 posted_flag = 0,
			 process_group_num = ""
		 WHERE process_group_num = @process_group_num
		 AND posted_flag = -1

 
		 COMMIT TRAN ABORT

		END
	ELSE
		BEGIN
		 BEGIN TRAN ABORT
 
		 

		 DELETE apvchdr
		 WHERE process_ctrl_num = @process_group_num
		 AND state_flag = -1

		 	
		 UPDATE apchkstb
		 SET apchkstb.check_num = #check_header.old_doc_ctrl
		 FROM apchkstb,#check_header
		 WHERE apchkstb.payment_num = #check_header.trx_ctrl_num
		 AND apchkstb.posted_flag = -1

		 UPDATE apchkstb
		 SET posted_flag = 0
		 FROM apchkstb, apinppyt
		 WHERE apchkstb.payment_num = apinppyt.trx_ctrl_num
		 AND apinppyt.process_group_num = @process_group_num
		 AND apchkstb.posted_flag = -1
		 AND apinppyt.posted_flag = -1	

		 	
		 UPDATE apexpdst
		 SET apexpdst.check_num = #check_header.old_doc_ctrl
		 FROM apexpdst,#check_header
		 WHERE apexpdst.payment_num = #check_header.trx_ctrl_num
		 AND apexpdst.posted_flag = -1

		 UPDATE apexpdst
		 SET posted_flag = 0
		 FROM apexpdst, apinppyt
		 WHERE apexpdst.payment_num = apinppyt.trx_ctrl_num
		 AND apinppyt.process_group_num = @process_group_num
		 AND apexpdst.posted_flag = -1
		 AND apinppyt.posted_flag = -1	
		 

		 UPDATE apinppyt
		 SET apinppyt.doc_ctrl_num = #check_header.old_doc_ctrl,
		 apinppyt.printed_flag = 0,
			 apinppyt.posted_flag = 0,
			 apinppyt.process_group_num = ""
		 FROM apinppyt, #check_header
		 WHERE apinppyt.trx_ctrl_num = #check_header.trx_ctrl_num
		 AND apinppyt.process_group_num = @process_group_num
		 AND apinppyt.posted_flag = -1


		 COMMIT TRAN ABORT
		END

IF ( @debug_level > 1 ) SELECT CONVERT(char,getdate(),109) + "  " + "tmp/apchkabt.sp" + ", line " + STR( 151, 5 ) + " -- EXIT: "

RETURN 0


GO
GRANT EXECUTE ON  [dbo].[apchkabt_sp] TO [public]
GO
