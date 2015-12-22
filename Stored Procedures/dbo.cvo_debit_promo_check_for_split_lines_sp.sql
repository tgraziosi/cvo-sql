SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
  
/*  
Copyright (c) 2012 Epicor Software (UK) Ltd  
Name:   cvo_debit_promo_check_for_split_lines_sp    
Project ID:  Issue 864  
Type:   Stored Procedure  
Description: If an order line has been split across two or more extensions, then tidy up credit amounts
Developer:  Chris Tyler  
  
History  
-------  

-- EXEC dbo.cvo_debit_promo_check_for_split_lines_sp 1419759,0
  
*/  
  
CREATE PROC [dbo].[cvo_debit_promo_check_for_split_lines_sp]	@order_no  INT,  
															@ext  INT
AS
BEGIN

	SET NOCOUNT ON


	DECLARE @line_no		INT,
			@current_ext	INT,
			@credit_amount	DECIMAL(20,8),
			@current_credit	DECIMAL(20,8)
			

	SET @line_no = 0
	WHILE 1=1 
	BEGIN

		SELECT TOP 1
			@line_no = line_no 
		FROM 
			dbo.CVO_debit_promo_customer_det (NOLOCK)
		WHERE 
			order_no = @order_no 
			AND ext > @ext
			AND line_no > @line_no
		GROUP BY 
			line_no
		HAVING 
			COUNT(1) > 1
		ORDER BY
			line_no

		IF @@ROWCOUNT = 0
			BREAK

		-- Get credit amount from original order
		SELECT
			@credit_amount = credit_amount
		FROM
			dbo.CVO_debit_promo_customer_det (NOLOCK)
		WHERE 
			order_no = @order_no 
			AND ext = @ext
			AND line_no = @line_no

		SET @current_ext = @ext

		WHILE @credit_amount > 0
		BEGIN
			SELECT TOP 1
				@current_ext = ext
			FROM
				dbo.CVO_debit_promo_customer_det (NOLOCK)
			WHERE 
				order_no = @order_no 
				AND ext > @current_ext
			ORDER BY
				ext

			IF @@ROWCOUNT = 0
				BREAK

			-- Get value of order line
			SELECT
				@current_credit = CASE ISNULL(discount,0) WHEN 0 THEN ROUND(curr_price * ordered,2) ELSE ROUND((curr_price * ordered) * ((100 - discount)/100) ,2) END
			FROM
				dbo.ord_list
			WHERE
				order_no = @order_no
				AND order_ext = @current_ext
				AND line_no = @line_no

			IF ISNULL(@current_credit,0) < @credit_amount
			BEGIN
				SET @credit_amount = @credit_amount - ISNULL(@current_credit,0)
			END
			ELSE
			BEGIN
				SET @current_credit = @credit_amount
				SET @credit_amount = 0
			END

			-- Update record
			IF ISNULL(@current_credit,0) > 0
			BEGIN
				UPDATE
					dbo.CVO_debit_promo_customer_det
				SET
					credit_amount = @current_credit
				WHERE
					order_no = @order_no
					AND ext = @current_ext
					AND line_no = @line_no
			END
			
			-- Update later orders if no more credit left
			IF @credit_amount = 0
			BEGIN
				UPDATE
					dbo.CVO_debit_promo_customer_det
				SET
					credit_amount = 0
				WHERE
					order_no = @order_no
					AND ext > @current_ext
					AND line_no = @line_no
			END
		END
	END
END  

GO
GRANT EXECUTE ON  [dbo].[cvo_debit_promo_check_for_split_lines_sp] TO [public]
GO
