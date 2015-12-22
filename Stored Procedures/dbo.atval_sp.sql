SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2008 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2008 Epicor Software Corporation, 2008    
                  All Rights Reserved                    
*/                                                

                                               







                                                

CREATE PROC [dbo].[atval_sp]
AS
BEGIN

	UPDATE x SET invalid_record = 10190
	FROM #atmtchdr x
	WHERE EXISTS (
		select b.invoice_no, a.vendor_code
		from	 #atmtchdr b, #atmtcdet c, atapvend a, atco d
		where	 b.invoice_no = c.invoice_no
		AND a.vendor_code = b.vendor_code
		AND d.voprocs_invoice_taxflag = 1
		AND x.vendor_code = b.vendor_code
		AND x.invoice_no = b.invoice_no
		group by b.invoice_no, a.vendor_code, b.amt_discount
		having( ( ABS( SUM( c.amt_discount ) ) - ABS( b.amt_discount ) > 0.0000001 )
		AND ABS( b.amt_discount ) > 0.0000001 ) 
		)

	UPDATE x SET invalid_record = 10220
	FROM #atmtchdr x
	WHERE EXISTS (
		select b.invoice_no, a.vendor_code
		from	 #atmtchdr b, #atmtcdet c, atapvend a, atco d
		where	 b.invoice_no = c.invoice_no
		AND a.vendor_code = b.vendor_code
		AND b.at_tax_calc_flag = 1
		AND x.vendor_code = b.vendor_code
		AND x.invoice_no = b.invoice_no
		group by b.invoice_no, a.vendor_code, b.amt_tax
		having( ( ABS( SUM( c.amt_tax ) ) - ABS( b.amt_tax ) > 0.0000001 )
		AND ABS( b.amt_tax ) > 0.0000001 ) 
		)
		
	UPDATE x SET invalid_record = 10250
	FROM #atmtchdr x
	WHERE EXISTS (
		select b.invoice_no, a.vendor_code
		from	 #atmtchdr b, #atmtcdet c, atapvend a, atco d
		where	 b.invoice_no = c.invoice_no
		AND a.vendor_code = b.vendor_code
		AND d.voprocs_invoice_taxflag = 1
		AND x.vendor_code = b.vendor_code
		AND x.invoice_no = b.invoice_no
		group by b.invoice_no, a.vendor_code, b.amt_freight
		having( ( ABS( SUM( c.amt_freight ) ) - ABS( b.amt_freight ) > 0.0000001 )
		AND ABS( b.amt_freight ) > 0.0000001 ) 
		)
	
	
	UPDATE x SET invalid_record = 10270
	FROM #atmtchdr x
	WHERE EXISTS (
		select b.invoice_no, a.vendor_code
		from	 #atmtchdr b, #atmtcdet c, atapvend a, atco d
		where	 b.invoice_no = c.invoice_no
		AND a.vendor_code = b.vendor_code
		AND d.voprocs_invoice_taxflag = 1
		AND x.vendor_code = b.vendor_code
		AND x.invoice_no = b.invoice_no
		group by b.invoice_no, a.vendor_code, b.amt_misc
		having( ( ABS( SUM( c.amt_misc ) ) - ABS( b.amt_misc ) > 0.0000001 )
		AND ABS( b.amt_misc ) > 0.0000001 ) 
		)

	UPDATE 	atmtchdr
	SET	status = 'R', 
		num_failed = hdr.num_failed + 1,
		error_desc = err.err_desc
	FROM	atmtchdr hdr, #atmtchdr h, epedterr err
	WHERE	hdr.invoice_no 	 = h.invoice_no
		AND	hdr.vendor_code  = h.vendor_code
		AND	h.invalid_record = err.err_code 
		AND err.err_code BETWEEN 10180 AND 10310 


	DELETE 	det
	FROM	#atmtchdr hdr, #atmtcdet det
	WHERE	hdr.invoice_no = det.invoice_no
		AND	hdr.vendor_code = det.vendor_code 
		AND	hdr.invalid_record BETWEEN 10180 AND 10310 

	DELETE #atmtchdr
	WHERE invalid_record BETWEEN 10180 AND 10310 

END

                                              
/**/                                              
GO
GRANT EXECUTE ON  [dbo].[atval_sp] TO [public]
GO
