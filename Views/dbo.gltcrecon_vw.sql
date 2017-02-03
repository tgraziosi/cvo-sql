SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[gltcrecon_vw] AS  SELECT  g.timestamp, g.trx_ctrl_num, g.trx_type, g.doc_ctrl_num, g.app_id,  
      g.posted_flag, g.remote_doc_id, g.remote_state, g.reconciled_flag, g.amt_gross, g.amt_tax,   
      g.remote_amt_gross, g.remote_amt_tax, g.customervendor_code, g.date_doc, g.reconciliated_date  
      FROM gltcrecon g, arinpchg h  
    WHERE  
     g.trx_type in (2031,2032) AND ((g.posted_flag = 2)   
     OR (g.posted_flag = 0 AND g.remote_state = 2)   
     OR (g.posted_flag = 0 AND g.remote_state = 3 AND g.reconciled_flag = 0)   
     OR (g.posted_flag = 0 AND g.remote_state = 3 AND h.hold_flag = 1)   
     OR (g.posted_flag = 0 AND g.remote_state = 0)  
     OR (g.posted_flag = 1)) AND (g.trx_ctrl_num = h.trx_ctrl_num)   
    UNION SELECT  g.timestamp, g.trx_ctrl_num, g.trx_type, g.doc_ctrl_num, g.app_id,  
      g.posted_flag, g.remote_doc_id, g.remote_state, g.reconciled_flag, g.amt_gross, g.amt_tax,   
      g.remote_amt_gross, g.remote_amt_tax, g.customervendor_code, g.date_doc, g.reconciliated_date  
      FROM gltcrecon g, artrx h   
    WHERE g.trx_type in (2031,2032) AND ((g.posted_flag = 2)   
     OR (g.posted_flag = 1 AND g.remote_state = 0)  
     OR (g.posted_flag = 1 AND g.remote_state = 2)  
     OR (g.posted_flag = 1 AND g.remote_state = 1)  
     OR (g.posted_flag = 0 )) AND (g.trx_ctrl_num = h.trx_ctrl_num)  
   UNION SELECT  g.timestamp, g.trx_ctrl_num, g.trx_type, g.doc_ctrl_num, g.app_id,  
      g.posted_flag, g.remote_doc_id, g.remote_state, g.reconciled_flag, g.amt_gross, g.amt_tax,   
      g.remote_amt_gross, g.remote_amt_tax, g.customervendor_code, g.date_doc, g.reconciliated_date  
      FROM gltcrecon g, apinpchg h  
   WHERE  
    g.trx_type in (4091,4092) AND ((g.posted_flag = 2)   
     OR (g.posted_flag = 0 AND g.remote_state = 2)   
     OR (g.posted_flag = 0 AND g.remote_state = 3 AND g.reconciled_flag = 0)   
     OR (g.posted_flag = 0 AND g.remote_state = 3 AND h.hold_flag = 1)   
     OR (g.posted_flag = 0 AND g.remote_state = 0)  
     OR (g.posted_flag = 1)) AND (g.trx_ctrl_num = h.trx_ctrl_num)   
   UNION SELECT  g.timestamp, g.trx_ctrl_num, g.trx_type, g.doc_ctrl_num, g.app_id,  
      g.posted_flag, g.remote_doc_id, g.remote_state, g.reconciled_flag, g.amt_gross, g.amt_tax,   
      g.remote_amt_gross, g.remote_amt_tax, g.customervendor_code, g.date_doc, g.reconciliated_date  
      FROM gltcrecon g, apvohdr h   
   WHERE g.trx_type in (4091) AND ((g.posted_flag = 2)   
     OR (g.posted_flag = 1 AND g.remote_state = 0)  
     OR (g.posted_flag = 1 AND g.remote_state = 2)  
     OR (g.posted_flag = 1 AND g.remote_state = 1)  
     OR (g.posted_flag = 0 )) AND (g.trx_ctrl_num = h.trx_ctrl_num)  
   UNION SELECT  g.timestamp, g.trx_ctrl_num, g.trx_type, g.doc_ctrl_num, g.app_id,  
      g.posted_flag, g.remote_doc_id, g.remote_state, g.reconciled_flag, g.amt_gross, g.amt_tax,   
      g.remote_amt_gross, g.remote_amt_tax, g.customervendor_code, g.date_doc, g.reconciliated_date  
      FROM gltcrecon g, apdmhdr h   
   WHERE g.trx_type in (4092) AND ((g.posted_flag = 2)   
     OR (g.posted_flag = 1 AND g.remote_state = 0)  
     OR (g.posted_flag = 1 AND g.remote_state = 2)  
     OR (g.posted_flag = 1 AND g.remote_state = 1)  
     OR (g.posted_flag = 0 )) AND (g.trx_ctrl_num = h.trx_ctrl_num)
GO
GRANT REFERENCES ON  [dbo].[gltcrecon_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[gltcrecon_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[gltcrecon_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[gltcrecon_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[gltcrecon_vw] TO [public]
GO
