SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[ARWriteOffTotal_SP] @trx_ctrl_num varchar( 16 ) AS BEGIN  SELECT SUM(d.amt_applied ) 
 FROM arinppdt d, artrx t  WHERE d.trx_ctrl_num = @trx_ctrl_num  AND d.apply_to_num = t.doc_ctrl_num 
END 

 /**/
GO
GRANT EXECUTE ON  [dbo].[ARWriteOffTotal_SP] TO [public]
GO
