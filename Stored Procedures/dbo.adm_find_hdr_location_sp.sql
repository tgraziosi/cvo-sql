SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[adm_find_hdr_location_sp] @search varchar(10), @module varchar(10), @mode varchar(30), 
  @sec_level int, @exclude_loc varchar(20) AS
BEGIN		
	Declare @loc varchar(10), @org_id varchar(30)

	if lower(@mode) = 'next'
        begin
          select @loc = min(location)
          from locations_hdr_vw where location not like @exclude_loc and isnull(void,'') != 'V' and module = @module
            and (@sec_level > 0 or curr_org_ind = 1)
            and location > @search
         
	  if @loc is NULL set @mode = 'last'
	end 

	if lower(@mode) = 'prev'
        begin
          select @loc = min(location)
          from locations_hdr_vw where location not like @exclude_loc and isnull(void,'') != 'V' and module = @module
            and (@sec_level > 0 or curr_org_ind = 1) and location < @search

	  if @loc is NULL set @mode = 'first'
	end 

	if lower(@mode) = 'first'
          select @loc = min(location)
          from locations_hdr_vw where location not like @exclude_loc and isnull(void,'') != 'V' and module = @module
            and (@sec_level > 0 or curr_org_ind = 1)

	if lower(@mode) = 'last'
          select @loc = max(location)
          from locations_hdr_vw where location not like @exclude_loc and isnull(void,'') != 'V' and module = @module
            and (@sec_level > 0 or curr_org_ind = 1)

	if lower(@mode) in ( 'get','validate')
          select @loc = min(location)
          from locations_hdr_vw where location not like @exclude_loc and isnull(void,'') != 'V' and module = @module
            and (@sec_level > 0 or curr_org_ind = 1) and location = @search

	if lower(@mode) = 'get_void'
          select @loc = min(location)
          from locations_hdr_vw where location not like @exclude_loc and module = @module
            and (@sec_level > 0or curr_org_ind = 1) and location = @search


	SELECT location,name,  addr1,
          addr2, addr3,
          addr4, addr5,
			 phone, aracct_code,
			 apacct_code,
			 organization_id,
			 city,  state,
			 zip,   country_code
	from locations_all l (nolock)
	WHERE l.location = @loc 

END
GO
GRANT EXECUTE ON  [dbo].[adm_find_hdr_location_sp] TO [public]
GO
