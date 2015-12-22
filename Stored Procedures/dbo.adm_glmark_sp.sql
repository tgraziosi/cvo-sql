SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[adm_glmark_sp] AS 
BEGIN          UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = 'MANU'          UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = '2031'   AND src_doc_num IN (SELECT doc_ctrl_num FROM artrx WHERE trx_type = 2031) 
         IF @@error <> 0 RETURN 8100             UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = '2032'   AND src_doc_num IN (SELECT doc_ctrl_num FROM artrx WHERE trx_type = 2032) 
         IF @@error <> 0 RETURN 8100     

UPDATE #gl_glinphdr SET post_flag = 1  
WHERE post_flag <> 1 
 AND src_trx_id = '4091'  AND src_doc_num IN (SELECT trx_ctrl_num FROM adm_apvohdr)  
IF @@error <> 0 RETURN 8100 

    UPDATE #gl_glinphdr SET post_flag = 1  WHERE post_flag <> 1  AND src_trx_id = '4092' 
 AND src_doc_num IN (SELECT trx_ctrl_num FROM apdmhdr)  IF @@error <> 0 RETURN 8100 
    UPDATE #gl_glinphdr SET post_flag = 1  WHERE post_flag <> 1  AND src_trx_id = 'OEIV' 
 AND src_doc_num IN (SELECT order_ctrl_num FROM artrx WHERE trx_type = 2031)  IF @@error <> 0 RETURN 8100 
    UPDATE #gl_glinphdr SET post_flag = 1  WHERE post_flag <> 1  AND src_trx_id = 'OECM' 
 AND src_doc_num IN (SELECT order_ctrl_num FROM artrx WHERE trx_type = 2032)  IF @@error <> 0 RETURN 8100 

UPDATE #gl_glinphdr SET post_flag = 1  
WHERE post_flag <> 1  AND src_trx_id = 'PMVO' 
 AND src_doc_num IN  (SELECT  CONVERT(char(16), po_ctrl_num) + CONVERT(char(20), vend_order_num) FROM adm_apvohdr)  
IF @@error <> 0 RETURN 8100     

UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = 'PMDM'  AND src_doc_num IN  (SELECT  CONVERT(char(16), po_ctrl_num) + CONVERT(char(20), vend_order_num) 
 FROM apdmhdr)  IF @@error <> 0 RETURN 8100     UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = 'IVSH'  AND src_doc_num IN (SELECT CONVERT(char(16), tran_no) 
 FROM in_gltrxdet  WHERE trx_type = 'X' AND posted_flag = 'S')  AND src_doc_num IN (SELECT CONVERT(char(16), xfer_no) 
 FROM xfers_all  WHERE NOT date_shipped IS NULL)  IF @@error <> 0 RETURN 8100     UPDATE #gl_glinphdr SET post_flag = 1 
 WHERE post_flag <> 1  AND src_trx_id = 'IVRV'  AND src_doc_num IN (SELECT CONVERT(char(16), tran_no) 
 FROM in_gltrxdet  WHERE trx_type = 'X' AND posted_flag = 'S')  AND src_doc_num IN (SELECT CONVERT(char(16), xfer_no) 
 FROM xfers_all  WHERE NOT date_recvd IS NULL)  IF @@error <> 0 RETURN 8100  RETURN 0 
END 
GO
GRANT EXECUTE ON  [dbo].[adm_glmark_sp] TO [public]
GO
