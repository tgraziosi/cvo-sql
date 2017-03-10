SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_web_email_invoice_sp]
    @cust_code VARCHAR(12) ,
	@document VARCHAR(16), 
    @email_address VARCHAR(255) 


-- Exec cvo_web_email_invoice_sp '036320',  'INV0069464', 'tgraziosi@cvoptical.com'

-- select * from artrx where doc_ctrl_num = 'INV0069464'

-- select * from cvo_email_ship_confirmation

-- all params are required.  customer and document must be related.  the document can be either an order number, invoice number, or credit memo # 
AS
    BEGIN
        SET NOCOUNT ON;

        DECLARE @doc_ctrl_num VARCHAR(16) ,
            @order_no INT ,
            @order_ext INT ,
            @pos INT ,
            @ret_msg VARCHAR(510) ,
            @submit_msg VARCHAR(255) ,
            @error_msg VARCHAR(255) ,
            @row_id INT;
            
-- Processing
            
        SET @doc_ctrl_num = @document;

        SET @order_no = 0;
		SET @error_msg = NULL;
			
        SELECT  @order_no = order_no ,
                @order_ext = order_ext
        FROM    orders_invoice (NOLOCK)
        WHERE   doc_ctrl_num = @doc_ctrl_num;


        IF ( @order_no IS NULL
             OR @order_no = 0
           )
            BEGIN
                IF ( @error_msg IS NULL )
                    BEGIN
                        IF ( @doc_ctrl_num <> '' )
                            SET @error_msg = 'The document does not exist.'
                                + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num,
                                                              '');
                    END;
                ELSE
                    BEGIN
                        SET @error_msg = @error_msg + CHAR(13) + CHAR(10)
                            + @doc_ctrl_num; 
                    END;
            END;

			IF NOT EXISTS ( SELECT  1
                        FROM    orders_invoice oi
                                JOIN orders o ON o.order_no = oi.order_no
                                                 AND o.ext = oi.order_ext
                        WHERE   cust_code = @cust_code
                                AND oi.doc_ctrl_num = @doc_ctrl_num )
            BEGIN
                IF ( @error_msg IS NULL )
                    BEGIN
                        IF ( @doc_ctrl_num <> '' )
                            SET @error_msg = 'The customer on the document does not match customer passed.'
                                + CHAR(13) + CHAR(10) + ISNULL(@doc_ctrl_num, '');
                    END;
                ELSE
                    BEGIN
                        SET @error_msg = @error_msg + CHAR(13) + CHAR(10) + @doc_ctrl_num; 
                    END;
            END; 

			-- END VALIDATIONS

        IF @error_msg IS NULL
            BEGIN

                INSERT  dbo.cvo_email_ship_confirmation
                        ( order_no ,
                          order_ext ,
                          email_address ,
                          email_sent ,
                          invoice_no ,
                          doc_ctrl_num ,
                          etype
                        )
                        SELECT  a.order_no ,
                                a.ext ,
                                @email_address ,
                                0 ,
                                b.invoice_no ,
                                d.doc_ctrl_num ,
                                1
                        FROM    CVO_orders_all a ( NOLOCK )
                                JOIN orders_all b ( NOLOCK ) ON a.order_no = b.order_no
                                                              AND a.ext = b.ext
                                JOIN armaster_all c ( NOLOCK ) ON b.cust_code = c.customer_code
                                JOIN orders_invoice d ( NOLOCK ) ON a.order_no = d.order_no
                                                              AND a.ext = d.order_ext
                        WHERE   a.order_no = @order_no
                                AND a.ext = @order_ext
                                AND c.address_type = CASE WHEN b.ship_to = ''
                                                          THEN 0
                                                          ELSE 1
                                                     END
                                AND c.ship_to_code = CASE WHEN b.ship_to = ''
                                                          THEN c.ship_to_code
                                                          ELSE b.ship_to
                                                     END; 

                SELECT  @row_id = @@IDENTITY;

                IF EXISTS ( SELECT  1
                            FROM    dbo.cvo_email_ship_confirmation
                            WHERE   row_id = @row_id
                                    AND email_address IS NULL )
                    BEGIN
                        DELETE  dbo.cvo_email_ship_confirmation
                        WHERE   row_id = @row_id;
                        IF ( @error_msg IS NULL )
                            BEGIN
                                IF ( @doc_ctrl_num <> '' )
                                    SET @error_msg = 'The following document has not been submitted.'
                                        + CHAR(13) + CHAR(10)
                                        + ISNULL(@doc_ctrl_num, '')
                                        + ' -  No email address';
                            END;
                        ELSE
                            BEGIN
                                SET @error_msg = @error_msg + CHAR(13)
                                    + CHAR(10) + @doc_ctrl_num
                                    + ' -  No email address';
                            END;					
                    END;
                ELSE
                    BEGIN
                        IF ( @submit_msg IS NULL )
                            BEGIN
                                SET @submit_msg = 'The following document has been submitted.'
                                    + CHAR(13) + CHAR(10) + @doc_ctrl_num;
                            END;
                        ELSE
                            BEGIN
                                SET @submit_msg = @submit_msg + CHAR(13)
                                    + CHAR(10) + @doc_ctrl_num;
                            END;
                    END;
			
            END; -- main processing loop
		
	-- Return Message
        IF ( @error_msg IS NULL )
            BEGIN
                SET @ret_msg = ISNULL(@submit_msg, 'No Data Submitted')
                    + CHAR(13) + CHAR(10) + ISNULL(@error_msg, '');
            END;
        ELSE
            BEGIN
                SET @ret_msg = ISNULL(@submit_msg, '') + CHAR(13) + CHAR(10)
                    + ISNULL(@error_msg, '');
            END;
		
        SELECT  @ret_msg;

		RETURN(0);

    END;

    GRANT EXECUTE ON cvo_web_email_invoice_sp TO PUBLIC;


GO
GRANT EXECUTE ON  [dbo].[cvo_web_email_invoice_sp] TO [public]
GO
