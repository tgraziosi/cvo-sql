SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_sub] @search varchar(255), @sort char(1), 
                 @cust varchar(10), @part varchar(30), @loc varchar(10), @sellable char(1) = 'Y'  AS

declare @x int

if @cust <> 'ALL' begin
   select @x = count(*) from inv_substitutes
          where part_no = @part and customer_key = @cust
   if @x is null begin
      select @x = 0
   end
   if @x <= 0 begin
      select @cust = 'ALL'
   end
end
set rowcount 100

if @sort='D'
begin
	IF @sellable = 'N'
	BEGIN
		SELECT x.priority, x.sub_part, i.[description], ( i.in_stock - i.commit_ed ), x.part_no
		  FROM dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
		 WHERE x.sub_part = i.part_no 
		   AND x.customer_key = @cust
		   AND x.part_no = @part		-- mls 9/27/05 SCR 32011
		   AND i.location = @loc 
		   AND i.[description] >= @search
		   AND (i.non_sellable_flag IS NULL OR i.non_sellable_flag = 'N')
		ORDER BY i.[description], x.sub_part

		SET rowcount 0
		RETURN
	END

  SELECT x.priority, x.sub_part, i.description, 
         ( i.in_stock - i.commit_ed ), x.part_no
  FROM   dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
  WHERE  x.sub_part = i.part_no AND x.customer_key = @cust 
    AND x.part_no = @part		-- mls 9/27/05 SCR 32011
    AND i.location = @loc AND i.description >= @search
  ORDER BY i.description, x.sub_part
end

if @sort='I'
begin
	IF @sellable = 'N'
	BEGIN
		SELECT x.priority, x.sub_part, i.[description], ( i.in_stock - i.commit_ed ), x.part_no
		  FROM dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
		 WHERE x.sub_part = i.part_no 
		   AND x.customer_key = @cust
		   AND x.part_no = @part		-- mls 9/27/05 SCR 32011
		   AND i.location = @loc
		   AND x.sub_part >= @search
		   AND (i.non_sellable_flag IS NULL OR i.non_sellable_flag = 'N')
		ORDER BY x.sub_part

		SET rowcount 0
		RETURN
	END

  SELECT x.priority, x.sub_part, i.description, 
         ( i.in_stock - i.commit_ed ), x.part_no
  FROM   dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
  WHERE  x.sub_part = i.part_no AND x.customer_key = @cust
    AND x.part_no = @part		-- mls 9/27/05 SCR 32011
    and i.location = @loc AND x.sub_part >= @search
  ORDER BY x.sub_part
end

if @sort='P'
begin
	IF @sellable = 'N'
	BEGIN
		SELECT x.priority, x.sub_part, i.[description], ( i.in_stock - i.commit_ed ), x.part_no
		  FROM dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
		 WHERE x.sub_part = i.part_no
		   AND x.customer_key = @cust
		   AND x.part_no = @part		-- mls 9/27/05 SCR 32011
		   AND i.location = @loc
		   AND (i.non_sellable_flag IS NULL OR i.non_sellable_flag = 'N')
		ORDER BY x.priority, x.sub_part

		SET rowcount 0
		RETURN
	END

  SELECT x.priority, x.sub_part, i.description, 
         ( i.in_stock - i.commit_ed ), x.part_no
  FROM   dbo.inv_substitutes x ( NOLOCK ), dbo.inventory i ( NOLOCK )
  WHERE  x.sub_part = i.part_no AND x.customer_key = @cust 
    AND x.part_no = @part		-- mls 9/27/05 SCR 32011
    and i.location = @loc
  ORDER BY x.priority, x.sub_part
end

if @sort='T'
begin
  set rowcount 0

	IF @sellable = 'N'
	BEGIN
		SELECT x.priority, x.sub_part, i.[description], 0, x.part_no
		  FROM dbo.inv_substitutes x ( NOLOCK ), dbo.inv_master i ( NOLOCK )
		 WHERE x.sub_part = i.part_no
		   AND x.part_no = @part
		   AND x.customer_key = @cust
		   AND (i.non_sellable_flag IS NULL OR i.non_sellable_flag = 'N')
		ORDER BY x.priority, x.sub_part

		SET rowcount 0
		RETURN
	END

  SELECT x.priority, x.sub_part, i.description, 
         0, x.part_no
  FROM   dbo.inv_substitutes x ( NOLOCK ), dbo.inv_master i ( NOLOCK )
  WHERE  x.sub_part = i.part_no AND x.part_no = @part 
    and x.customer_key = @cust
  ORDER BY x.priority, x.sub_part
end
set rowcount 0
GO
GRANT EXECUTE ON  [dbo].[get_q_sub] TO [public]
GO
