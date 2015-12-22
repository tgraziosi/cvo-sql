SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cc_nat_accts_create_table_sp] @style smallint
	AS

		SET NOCOUNT ON

		DECLARE @rptname varchar(80),
						@info	varchar(100),
						@table	varchar(100)

		SELECT @rptname = rptname FROM cvo_control..rmcrstal WHERE rid = 4632 and num = 0 and style = @style
		SELECT @rptname = REPLACE(@rptname, '.\crystal\', '' )
		SELECT @rptname = REPLACE(@rptname, '.rpt', '_cvo.rpt' )

		SELECT @info = info FROM cvo_control..rminfo WHERE rid = 4632 and num = 0 and style = @style
		BEGIN TRANSACTION 
			UPDATE cvo_control..rnum SET next_num = (next_num + 1)%10000
			SELECT @table = '##rpt' + convert(varchar(16), next_num-1) FROM cvo_control..rnum
		COMMIT TRANSACTION 

		SELECT @table = @table + '_' + @info

		EXEC(	'	IF EXISTS (	SELECT * 
								FROM tempdb..sysobjects 
								WHERE name = "' + @table + '" ) ' +
					'	DROP TABLE ' + @table )

		
		EXEC(	'	CREATE TABLE ' + @table +
					'	(	trx_type smallint NULL, 
							ref_id smallint NULL, 
							trx_ctrl_num varchar(16) NULL, 
							doc_ctrl_num varchar(16) NULL, 
							order_ctrl_num varchar(16) NULL, 
							cust_po_num varchar(20) NULL, 
							cash_acct_code varchar(32) NULL, 
							apply_to_num varchar(16) NULL, 
							apply_trx_type smallint NULL, 
							sub_apply_num varchar(16) NULL, 
							sub_apply_type smallint NULL, 
							date_doc datetime NULL, 
							date_due datetime NULL, 
							date_aging datetime NULL, 
							date_applied datetime NULL, 
							amount float NULL, 
							customer_code varchar(8) NULL, 
							nat_cur_code varchar(8) NULL, 
							rate_type varchar(8) NULL, 
							rate_home float NULL, 
							rate_oper float NULL, 
							customer_name varchar(40) NULL, 
							contact_name varchar(40) NULL, 
							contact_phone varchar(40) NULL, 
							attention_name varchar(40) NULL, 
							attention_phone varchar(30) NULL, 
							addr1 varchar(40) NULL, 
							addr2 varchar(40) NULL, 
							addr3 varchar(40) NULL, 
							addr4 varchar(40) NULL, 
							addr5 varchar(40) NULL, 
							addr6 varchar(40) NULL, 
							status_desc varchar(40) NULL, 
							parent varchar(8) NULL, 
							child_1 varchar(8) NULL, 
							child_2 varchar(8) NULL, 
							child_3 varchar(8) NULL, 
							child_4 varchar(8) NULL, 
							child_5 varchar(8) NULL, 
							child_6 varchar(8) NULL, 
							child_7 varchar(8) NULL, 
							child_8 varchar(8) NULL, 
							child_9 varchar(8) NULL, 
							groupby0 varchar(40) NULL, 
							groupby1 varchar(40) NULL, 
							groupby2 varchar(40) NULL, 
							groupby3 varchar(40) NULL, 
							bracket smallint NULL, 
							days_aged int NULL, 
							trx_type_code varchar(8) NULL, 
							status_type smallint NULL, 
							symbol varchar(8) NULL, 
							curr_precision smallint NULL, 
							num_currencies smallint NULL,
							date_entered int NULL,
							org_id varchar(30) NULL,
							region_id varchar(30) NULL	) ' )

	SELECT @table, @rptname

	SET NOCOUNT OFF

GO
GRANT EXECUTE ON  [dbo].[cc_nat_accts_create_table_sp] TO [public]
GO
