SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/* PVCS Revision or Version:Revision              
I:\vcs\ar\vw\arunpinv.VWv - ERA7.0B.4 : 1.5
              Confidential Information                  
   Limited Distribution of Authorized Persons Only      
   Created 1999 and Protected as Unpublished Work       
         Under the U.S. Copyright Act of 1976           
Copyright (c) 1999 Epicor Software Corporation, 1999  
                 All Rights Reserved                    
*/                                                                                              


/* MODIFICATION LOG 
**
** Modification Marker	:  CB0001
** Client		:  
** Author		:  The Emerald Group - JDB
** Date			:  10/26/98
** Detail Design	:  Chargeback Modification
** Description		:  Added document description, po number, open amount and 
**			   document date to view for chargeback processing.
**
**/


/* Begin mod: CB0001 - Comment out the original code
CREATE VIEW arunpinv_vw
AS 
	SELECT	customer_code, artrx.doc_ctrl_num, artrx.nat_cur_code
	FROM 	artrx
	WHERE	doc_ctrl_num = apply_to_num
	AND	trx_type = apply_trx_type
	AND 	paid_flag = 0 
	AND	void_flag = 0
* End mod: CB0001 */

/* Begin mod: CB0001 - 	Added document description, po number, open amount and document date
			to view for chargeback processing */
    
                     CREATE VIEW [dbo].[arunpinv_vw] (customer_code, doc_ctrl_num, DocDesc, Open_Amt, Date_Doc, Cust_Po_Num, nat_cur_code) AS  
SELECT artrx.customer_code, artrx.doc_ctrl_num, artrx.doc_desc,  
(artrx.amt_tot_chg - artrx.amt_paid_to_date), convert(varchar(12), dateadd(dd, artrx.date_doc - 639906, '1/1/1753'),101),
artrx.cust_po_num, artrx.nat_cur_code 
FROM artrx LEFT OUTER JOIN arinppdt 
	ON (artrx.doc_ctrl_num = arinppdt.apply_to_num
	 AND arinppdt.amt_tot_chg > arinppdt.amt_applied + arinppdt.amt_paid_to_date)
WHERE artrx.doc_ctrl_num = artrx.apply_to_num  
AND artrx.trx_type = artrx.apply_trx_type 
AND artrx.paid_flag = 0  
AND artrx.void_flag = 0  

/* End mod: CB0001 */

/**/                                              
GO
GRANT REFERENCES ON  [dbo].[arunpinv_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arunpinv_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arunpinv_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arunpinv_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arunpinv_vw] TO [public]
GO
