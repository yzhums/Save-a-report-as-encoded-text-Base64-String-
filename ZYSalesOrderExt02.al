tableextension 50114 ZYSalesHeaderExt extends "Sales Header"
{
    fields
    {
        field(50101; "Large Text"; Blob)
        {
            Caption = 'Large Text';
            DataClassification = CustomerContent;
        }
    }
}
pageextension 50114 ZYSalesOrderExt extends "Sales Order"
{
    layout
    {
        addlast(General)
        {
            field(LargeText; LargeText)
            {
                Caption = 'Large Text';
                ApplicationArea = All;
                MultiLine = true;
                ShowCaption = false;
                trigger OnValidate()
                begin
                    SetLargeText(LargeText);
                end;
            }
        }
    }

    actions
    {
        addafter(Post)
        {
            action(SaveReportAsEncodedText)
            {
                Caption = 'Save Sales Report As Encoded Text';
                Image = Transactions;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    Base64Convert: Codeunit "Base64 Convert";
                    InStr: InStream;
                    OutStr: OutStream;
                    TempBlob: Codeunit "Temp Blob";
                    ReportParameters: text;
                begin
                    ReportParameters := Report.RunRequestPage(Report::"Standard Sales - Order Conf.");
                    TempBlob.CreateOutStream(OutStr);
                    Report.SaveAs(Report::"Standard Sales - Order Conf.", ReportParameters, ReportFormat::Pdf, OutStr);
                    TempBlob.CreateInStream(InStr);
                    LargeText := Base64Convert.ToBase64(InStr, false);
                    SetLargeText(LargeText);
                end;
            }
        }
    }
    var
        LargeText: Text;

    trigger OnAfterGetRecord()
    begin
        LargeText := GetLargeText();
    end;

    procedure SetLargeText(NewLargeText: Text)
    var
        OutStream: OutStream;
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Get(Rec."Document Type", Rec."No.");
        SalesHeader."Large Text".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(LargeText);
        SalesHeader.Modify();
    end;

    procedure GetLargeText() NewLargeText: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        Rec.CalcFields("Large Text");
        Rec."Large Text".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), Rec.FieldName("Large Text")));
    end;
}
