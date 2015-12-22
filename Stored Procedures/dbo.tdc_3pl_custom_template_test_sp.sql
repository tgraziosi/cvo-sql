SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_3pl_custom_template_test_sp]
	@customer	varchar(10),
	@ship_to	varchar(10),
	@location	varchar(10),
	@template_name	varchar(30),
	@currency	varchar(8),
	@begin_date	datetime,
	@end_date	datetime,
	@cost		decimal(20,8) OUTPUT
AS
/*BEGIN HELP*/
--  What is this?
--    Basically, this is a template to a stored procedure that you can use to create custom stored procedures of your own; 
--  to function alongside 3PL processing. You basically need to replace every occurence of the name 'tdc_3pl_custom_template_test_sp'
--  with the name you want to call your stored procedure, but you do want to make sure that a database object with your name does not
--  already exist in the database. Use the following SQL statement to test to see if the object you are trying to create already exists
--  in the database. If it does exist and you don't want to replace the object, then change the name of the object, but if it doesn't exist
--  you are ready to go ahead and create your new database object. A good naming convention for custom database objects such as tables 
--  and stored procedure is to use some type of abreviation of your company name. Example: Suppose you have a hardware store called
--  Ma's and Pa's Hardware, then you could create your own custom stored procedures like this MaAndPaHDW_Customer_sp  The 'sp' on the end
--  could tell you at a glance that your object is a stored procedure. MaAndPaHDW_CustomerData_tbl  The 'tbl' on the end could tell you
--  at a glance that your object is a table.
	/* **BEGIN**		SCRIPT USED TO SEE IF AN OBJECT EXISTS			*/
	-- IF OBJECT_ID('tdc_3pl_custom_template_test_sp') IS NOT NULL
	-- 	PRINT 'OBJECT EXISTS'
	-- ELSE
	-- 	PRINT 'OBJECT DOES NOT EXIST'
	/* **END**		SCRIPT USED TO SEE IF AN OBJECT EXISTS			*/

--  What can I do with this stored procedure/functionality?
--    This stored procedure can be used to meet any custom 3PL need that cannot be met using the existing tools provided
--  such as inv storage for both fixed bins and distinct bins, labor related processing, and fixed charge values. This custom
--  stored procedure would allow you to charge a custom amount based on the customer, ship_to, location, template, currency, 
--  begin_date, and end_date. Suppose you have a customer that you deal with on a regular basis that has multiple ship to locations.
--  Using this stored procedure, you could easily distinguish between ship_to's for a given customer and make sure that if a specific
--  location required additional 'charges', then you could incorporate the logic into your custom stored procedure to charge the
--  additional amount based on the ship to.
/*  Example:
	In this example we are specifying the charge based on the ship_to location
--------------------------------------------------------------------------------------
    IF @ship_to = '001'
	SELECT @cost = 50
    ELSE IF @ship_to = '002'
	SELECT @cost = 100
    ELSE
	SELECT @cost = 25
*/

--  What must my custom stored procedure have in common with this template?
--  Here are the requirements: 
--    With your custom stored procedure, YOU CAN CHANGE THE NAME to anything you want, your
--  logic is just that, completely YOUR OWN CUSTOM LOGIC, which should, but doesn't have to be based on the parameters
--  that we pass into your stored procedure.  The VARIABLE NAMES SHOULD REMAIN THE SAME, but don't have to, however, 
--  the NUMBER OF PARAMETERS, the ORDER OF THE PARAMETERS, and the DATATYPE FOR EACH PARAMETER MUST STAY THE SAME.
--  Also, please note that the last parameter @cost has the word OUTPUT after it, that means the value in the variable/parameter
--  @cost will be passed out of the stored procedure and we (TDC Solutions) will be able to use that value in the calculation
--  of the automatically generated order/quote amount.

--  How do we stop the 3PL order processing if our stored procedure finds an error that needs the user's attention?
--    We allow you to raise errors within your stored procedure(s) should you discover that processing needs to be halted until
--  something is rectified. For example, suppose you have written a custom stored procedure as part of a 3PL template and your
--  stored procedure charges a customer (@customer) a certain amount based on the inventory levels within your warehouse. 
--  Should inventory levels fall beneath a certain value or go above a certain value, you may want to raise an error and prevent
--  the quote from being generated until the inventory levels are fixed.
/*END HELP*/



	--Replace the following with logic of your own to trap for errors when your custom stored procedure is called

	--IF @customer = 'Some Customer
	--BEGIN
	--  RAISERROR('Your error message goes here!', 16, 1)
	--END

	--This is the value that you are returning from your stored procedure-+
	SELECT @cost = 50

RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_3pl_custom_template_test_sp] TO [public]
GO
