SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[sp_CRMLoad_SaveResults]

AS

EXEC dbo.sp_CRMLoad_SaveResults_XML 'Account_Std'
EXEC dbo.sp_CRMLoad_SaveResults_XML 'Account_Custom'
EXEC dbo.sp_CRMLoad_SaveResults_XML 'Contact_Std'
EXEC dbo.sp_CRMLoad_SaveResults_XML 'Contact_Custom'


/****** Object:  StoredProcedure [dbo].[sp_CRMProcess_ConcatIDs]    Script Date: 5/2/2017 1:37:29 PM ******/
SET ANSI_NULLS ON
GO
