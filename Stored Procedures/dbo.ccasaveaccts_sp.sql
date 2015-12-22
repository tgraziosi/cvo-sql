SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2006 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2006 Epicor Software Corporation, 2006    
                  All Rights Reserved                    
*/                                                



CREATE PROC [dbo].[ccasaveaccts_sp]      @order_no int, @order_ext int, @trx_ctrl_num varchar(16),
				 @trx_type varchar(16), @customer_code varchar(8), @payment_code varchar (10),@acc varchar(255),
				 @date_last_used int
AS

DECLARE @key varchar(255)
DECLARE @ret int
DECLARE @ast int
DECLARE @trxnum varchar(16)
DECLARE @trxtype smallint
DECLARE @orderext int
DECLARE @orderno int
DECLARE @is_order smallint
DECLARE @companycode varchar(8)

SELECT @companycode = company_code from glco

IF( @order_no=0)
BEGIN
	SELECT @is_order =0
END
ELSE
BEGIN
	SELECT @is_order =1
END

SET NOCOUNT ON 

SET @ast = 0

SELECT @acc = dbo.CCADecode_fn(@acc)



SELECT @ast = CHARINDEX('*', @acc, 3)

IF(@ast>0)
BEGIN
	
	IF   EXISTS (		SELECT * FROM CVO_Control..ccacryptaccts 
				WHERE  	(	  trx_ctrl_num = @trx_ctrl_num
						  AND trx_type = @trx_type
	   					  AND @is_order =0
						  AND company_code = @companycode  
					)
					OR 	( order_no = @order_no
						  AND order_ext = @order_ext
						  AND @is_order =1 
						  AND company_code = @companycode  
						)
		    )
	BEGIN
		SELECT 1 
	END
	ELSE
	BEGIN
		SELECT @trxnum = trx_ctrl_num, @trxtype = trx_type, @orderno = order_no, @orderext = order_ext 
		FROM icv_ccinfo
		WHERE payment_code = @payment_code
		AND customer_code = @customer_code


		IF EXISTS(SELECT * FROM CVO_Control..ccacryptaccts WHERE (			( trx_ctrl_num = @trxnum
						  AND trx_type = @trxtype
	   					  AND @is_order =0 
                                                  AND company_code = @companycode )
					OR 	( order_no = @orderno
						  AND order_ext = @orderext
						  AND @is_order =1 
                                                  AND company_code = @companycode )
					))
		BEGIN
			INSERT CVO_Control..ccacryptaccts (company_code, order_no,order_ext, trx_ctrl_num , trx_type, customer_code , ccnumber , date_last_used )
			SELECT @companycode, @order_no, @order_ext, @trx_ctrl_num, @trx_type, @customer_code, ccnumber, datediff( day, '01/01/1900', GETDATE()) + 693596
			FROM CVO_Control..ccacryptaccts acc
			WHERE (			( trx_ctrl_num = @trxnum
						  AND trx_type = @trxtype
	   					  AND @is_order =0  
                                                  AND company_code = @companycode)
					OR 	( order_no = @orderno
						  AND order_ext = @orderext
						  AND @is_order =1  
                                                  AND company_code = @companycode)
					)
			SELECT 1
		END
		ELSE
			SELECT 0
	END 
END

ELSE
BEGIN
	SELECT @key = pub_key from CVO_Control..ccakeys

	SELECT @acc =dbo.CCAEncrypt_fn(@acc, @key)

	SELECT @date_last_used = datediff( day, '01/01/1900', GetDate()) + 693596

	DELETE CVO_Control..ccacryptaccts
	WHERE   
		(				( trx_ctrl_num = @trx_ctrl_num
						  AND trx_type = @trx_type
	   					  AND @is_order =0  
                                                  AND company_code = @companycode)
					OR 	( order_no = @order_no
						  AND order_ext = @order_ext
						  AND @is_order =1  
                                                  AND company_code = @companycode)
					) 

	INSERT INTO CVO_Control..ccacryptaccts (company_code, order_no,order_ext, trx_ctrl_num , trx_type, customer_code , ccnumber , date_last_used )
	VALUES (@companycode, @order_no, @order_ext,@trx_ctrl_num,@trx_type,@customer_code,@acc, @date_last_used)
	
	SELECT 1
END


/**/                                              
GO
GRANT EXECUTE ON  [dbo].[ccasaveaccts_sp] TO [public]
GO
