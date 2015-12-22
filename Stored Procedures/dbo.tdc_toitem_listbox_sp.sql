SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
/* Name:	tdc_toitem_listbox_sp		      	      		*/
/*									*/
/* Module:	WMS							*/
/*						      			*/
/* Input:						      		*/
/*	part_no    - 	Part Number			    		*/
/*	location  - 	To Location			      		*/
/*	qty  	  -	Quantity					*/
/*									*/
/* Description:								*/
/*	This stored procedure generates a table of acceptable parts for */
/*	to_item list boxes in Item Reclass Transaction			*/
/*									*/
/* Revision History:							*/
/* 	Date		Who	Description				*/
/*	----		---	-----------				*/
/* 	5/23/2000	IA	Initial					*/
/* 	8/08/2000	IA	Bug fix: Exclude Voided Items		*/
/*									*/
/************************************************************************/

CREATE PROCEDURE [dbo].[tdc_toitem_listbox_sp]
(
  @part_no 	varchar (30),
  @location 	varchar (10),
  @qty 		decimal(20,8)
)
AS

DECLARE @al_frac_flag int
SELECT  @al_frac_flag = 0

BEGIN
	-- we care abou allow fractions only if original part allow fractions and quantity with fractions
	SELECT @al_frac_flag = 1 
	FROM inventory
	WHERE part_no = @part_no 
	AND location = @location
	AND allow_fractions = 1
	AND CEILING(@qty) <> @qty

	-- check if original part I/O
	IF EXISTS (SELECT * FROM tdc_inv_list (nolock) WHERE part_no = @part_no AND location = @location)
		BEGIN
			IF (@al_frac_flag = 1)
				-- I/O parts allow fraction sencetive
				INSERT INTO #item_listbox (part_no)
					SELECT DISTINCT t.part_no 
					FROM inventory i (nolock), tdc_inv_list t (nolock) 
					WHERE t.location = @location 
					AND t.location = i.location
					AND t.part_no <> @part_no
					AND i.part_no = t.part_no
					AND i.status not in ('C', 'R', 'K', 'V')
					AND i.void <> 'V' 				-- IA 08/08/00 exclude voided items
					AND i.serial_flag = (SELECT serial_flag FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
					AND i.allow_fractions = 1
			ELSE
				-- I/O parts allow fraction non sencetive
				INSERT INTO #item_listbox (part_no)	
					SELECT DISTINCT t.part_no 
					FROM inventory i (nolock), tdc_inv_list t (nolock) 
					WHERE t.location = @location 
					AND t.location = i.location
					AND t.part_no <> @part_no
					AND i.part_no = t.part_no
					AND i.status not in ('C', 'R', 'K', 'V')
					AND i.void <> 'V' 				-- IA 08/08/00 exclude voided items
					AND i.serial_flag = (SELECT serial_flag FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
		END
	ELSE
		BEGIN
			IF (@al_frac_flag = 1)
				INSERT INTO #item_listbox (part_no) 	
					SELECT DISTINCT part_no 
					FROM inventory (nolock)
					WHERE location = @location 
					AND part_no <> @part_no
					AND status not in ('C', 'R', 'K', 'V')
					AND void <> 'V' 				-- IA 08/08/00 exclude voided items
					AND serial_flag = (SELECT serial_flag FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
					AND lb_tracking = (SELECT lb_tracking FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
					AND allow_fractions = 1
			ELSE
				INSERT INTO #item_listbox (part_no)	
					SELECT DISTINCT part_no 
					FROM inventory (nolock)
					WHERE location = @location 
					AND part_no <> @part_no
					AND status not in ('C', 'R', 'K', 'V')
					AND void <> 'V' 				-- IA 08/08/00 exclude voided items
					AND serial_flag = (SELECT serial_flag FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
					AND lb_tracking = (SELECT lb_tracking FROM inventory (nolock) WHERE location = @location AND part_no = @part_no)
		END

RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[tdc_toitem_listbox_sp] TO [public]
GO
