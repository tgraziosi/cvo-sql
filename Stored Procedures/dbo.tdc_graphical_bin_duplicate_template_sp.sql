SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_graphical_bin_duplicate_template_sp]
	@new_template_name	varchar(30),
	@current_template_id	int,
	@userid			varchar(50),
	@err_msg		varchar(255) OUTPUT
AS
	DECLARE
	@language	varchar(10),
	@newtemplateid	int

	SELECT @language = ISNULL(language, 'us_english') FROM tdc_sec (NOLOCK) WHERE userid = @userid
	
	IF EXISTS(SELECT * FROM tdc_graphical_bin_template (NOLOCK) WHERE template_name = @new_template_name)
	BEGIN
		--'Template name already exists, please enter a unique name for each template.'
		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 17
	  	RETURN -1
	END
	IF NOT EXISTS(SELECT * FROM tdc_graphical_bin_template (NOLOCK) WHERE template_id =  @current_template_id)
	BEGIN
		--'New template cannot be created because the specified template to copy from does not exist.'
		SELECT @err_msg = err_msg 
			FROM tdc_lookup_error (NOLOCK) WHERE language = @language AND module = 'GBV' AND trans = 'GBV_GEN' AND err_no = 18
		RETURN -2
	END

	--Copy the template header
	INSERT INTO tdc_graphical_bin_template (template_name, template_desc, view_by_index, location, bin_width, bin_height, vert_spacing, horz_spacing, show_empty_bins, show_captions, empty_bin_caption, part_filter_id)
		SELECT @new_template_name, template_desc, view_by_index, location, bin_width, bin_height, vert_spacing, horz_spacing, show_empty_bins, show_captions, empty_bin_caption, part_filter_id FROM tdc_graphical_bin_template WHERE template_id = @current_template_id

	--Get the template_id for the template we just copied/created
	SELECT @newtemplateid = template_id FROM tdc_graphical_bin_template (NOLOCK) WHERE template_name = @new_template_name

	--Insert values from the bin store table if they exist	
	INSERT INTO tdc_graphical_bin_store (template_id, row, col, bin_no)
		SELECT @newtemplateid, row, col, bin_no FROM tdc_graphical_bin_store (NOLOCK) WHERE template_id = @current_template_id

	--Insert values from the part filter table if they exist
	INSERT INTO tdc_bin_view_part_filter_tbl (template_id, part_no)
		SELECT @newtemplateid, part_no FROM tdc_bin_view_part_filter_tbl (NOLOCK) WHERE template_id = @current_template_id
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_graphical_bin_duplicate_template_sp] TO [public]
GO
