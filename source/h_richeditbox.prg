/*
 * $Id: h_richeditbox.prg $
 */
/*
 * ooHG source code:
 * RichEdit control
 *
 * Copyright 2005-2018 Vicente Guerra <vicente@guerra.com.mx>
 * https://oohg.github.io/
 *
 * Portions of this project are based upon Harbour MiniGUI library.
 * Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
 *
 * Portions of this project are based upon Harbour GUI framework for Win32.
 * Copyright 2001 Alexander S. Kresin <alex@belacy.belgorod.su>
 * Copyright 2001 Antonio Linares <alinares@fivetech.com>
 *
 * Portions of this project are based upon Harbour Project.
 * Copyright 1999-2018, https://harbour.github.io/
 */
/*
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file LICENSE.txt. If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1335,USA (or download from http://www.gnu.org/licenses/).
 *
 * As a special exception, the ooHG Project gives permission for
 * additional uses of the text contained in its release of ooHG.
 *
 * The exception is that, if you link the ooHG libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the ooHG library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the ooHG
 * Project under the name ooHG. If you copy code from other
 * ooHG Project or Free Software Foundation releases into a copy of
 * ooHG, as the General Public License permits, the exception does
 * not apply to the code that you add in this way. To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for ooHG, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 */


#include "oohg.ch"
#include "common.ch"
#include "hbclass.ch"
#include "i_windefs.ch"

CLASS TEditRich FROM TEdit

   DATA Type                      INIT "RICHEDIT" READONLY
   DATA nWidth                    INIT 120
   DATA nHeight                   INIT 240
   DATA OnSelChange               INIT Nil
   DATA lSelChanging              INIT .F.
   DATA lDefault                  INIT .T.

   METHOD Define
   METHOD FontColor               SETGET
   METHOD BackColor               SETGET
   METHOD RichValue               SETGET
   METHOD Events
   METHOD Events_Notify
   METHOD SetSelectionTextColor
   METHOD SetSelectionBackColor
   METHOD HideSelection
   METHOD GetSelText
   METHOD MaxLength               SETGET
   METHOD LoadFile
   METHOD SaveFile
   METHOD GetLastVisibleLine
   METHOD GetCharFromPos
   METHOD GetSelFont
   METHOD SetSelFont

   MESSAGE SetSelTextColor        METHOD SetSelectionTextColor
   MESSAGE SetSelBackColor        METHOD SetSelectionBackColor
   MESSAGE GetSelectionFont       METHOD GetSelFont
   MESSAGE SetSelectionFont       METHOD SetSelFont

   ENDCLASS

METHOD Define( ControlName, ParentForm, x, y, w, h, value, fontname, ;
               fontsize, tooltip, maxlength, gotfocus, change, lostfocus, ;
               readonly, break, HelpId, invisible, notabstop, bold, italic, ;
               underline, strikeout, field, backcolor, lRtl, lDisabled, ;
               selchange, fontcolor, nohidesel, OnFocusPos, novscroll, ;
               nohscroll, file, type, OnHScroll, OnVScroll, nInsType ) CLASS TEditRich

   Local ControlHandle, nStyle

   ASSIGN ::nWidth  VALUE w TYPE "N"
   ASSIGN ::nHeight VALUE h TYPE "N"
   ASSIGN ::nRow    VALUE y TYPE "N"
   ASSIGN ::nCol    VALUE x TYPE "N"

   ::SetForm( ControlName, ParentForm, FontName, FontSize, FontColor, BackColor, .T., lRtl )

   nStyle := ::InitStyle( ,, Invisible, NoTabStop, lDisabled ) + ;
             if( HB_IsLogical( readonly ) .AND. readonly, ES_READONLY, 0 ) + ;
             if( HB_IsLogical( nohidesel ) .AND. nohidesel, ES_NOHIDESEL, 0 ) + ;
             if( HB_IsLogical( novscroll ) .AND. novscroll, ES_AUTOVSCROLL, WS_VSCROLL ) + ;
             if( HB_IsLogical( nohscroll ) .AND. nohscroll, 0, WS_HSCROLL )

   ::SetSplitBoxInfo( Break, )
   ControlHandle := InitRichEditBox( ::ContainerhWnd, 0, ::ContainerCol, ::ContainerRow, ::Width, ::Height, nStyle, maxlength, ::lRtl )

   ::Register( ControlHandle, ControlName, HelpId,, ToolTip )
   ::SetFont( , , bold, italic, underline, strikeout )

   ::BackColor := ::BackColor
   ::FontColor := ::FontColor

   If Empty( file )
      ::SetVarBlock( Field, Value )
   Else
      ::LoadFile( file, type )
   EndIf

   ASSIGN ::OnHScroll   VALUE OnHScroll  TYPE "B"
   ASSIGN ::OnVScroll   VALUE OnVScroll  TYPE "B"
   ASSIGN ::OnLostFocus VALUE lostfocus  TYPE "B"
   ASSIGN ::OnGotFocus  VALUE gotfocus   TYPE "B"
   ASSIGN ::OnChange    VALUE change     TYPE "B"
   ASSIGN ::OnSelChange VALUE selchange  TYPE "B"
   ASSIGN ::nOnFocusPos VALUE OnFocusPos TYPE "N"
   ASSIGN ::nInsertType VALUE nInsType   TYPE "N"

   Return Self

METHOD LoadFile( cFile, nType ) CLASS TEditRich

   Local lRet := .F.

   ASSIGN cFile VALUE cFile TYPE "C" DEFAULT ""
   ASSIGN nType VALUE nType TYPE "N" DEFAULT 2
   If ! Empty( cFile ) .and. File( cFile )
      lRet := FileStreamIn( ::hWnd, cFile, nType )
   EndIf

   Return lRet

METHOD SaveFile( cFile, nType ) CLASS TEditRich

   Local lRet := .F.

   ASSIGN cFile VALUE cFile TYPE "C" DEFAULT ""
   ASSIGN nType VALUE nType TYPE "N" DEFAULT 2
   If ! Empty( cFile )
      lRet := FileStreamOut( ::hWnd, cFile, nType )
   EndIf

   Return lRet

METHOD RichValue( cValue ) CLASS TEditRich

   If VALTYPE( cValue ) $ "CM"
      RichStreamIn( ::hWnd, cValue )
   EndIf

   RETURN RichStreamOut( ::hWnd )

METHOD GetSelFont( lSelection ) CLASS TEditRich

   LOCAL aRet, nTextColor

   ASSIGN lSelection VALUE lSelection TYPE "L" DEFAULT .T.               // .F. means control's default font

   aRet := GetFontRTF( ::hWnd, iif( lSelection, 1, 0 ) )                 // { cFontName, nFontSize, lBold, lItalic, nTextColor, lUnderline, lStrikeout, nCharset }

   IF ! Empty( aRet[ 1 ] )
      nTextColor := aRet[ 5 ]
      aRet[ 5 ] := { GetRed( nTextColor ), GetGreen( nTextColor ), GetBlue( nTextColor ) }
   ELSE
      aRet[ 5 ] := { NIL, NIL, NIL }
   ENDIF

   RETURN aRet

METHOD SetSelFont( lSelection, cFontName, nFontSize, lBold, lItalic, aTextColor, lUnderline, lStrikeout, nMask ) CLASS TEditRich

   ASSIGN lSelection VALUE lSelection TYPE "L" DEFAULT .T.               // .F. means control's default font

   RETURN SetFontRTF( ::hWnd, iif( lSelection, 1, 0 ), cFontName, nFontSize, lBold, lItalic, RGB( aTextColor[1], aTextColor[2], aTextColor[3] ), lUnderline, lStrikeout, nMask )


#pragma BEGINDUMP

#include "hbapi.h"
#include "hbvm.h"
#include "hbstack.h"
#include <windows.h>
#include <commctrl.h>
#include <richedit.h>
#include "oohg.h"

#ifndef CFM_BACKCOLOR
   #define CFM_BACKCOLOR 0x04000000
#endif

static WNDPROC lpfnOldWndProc = 0;

static LRESULT APIENTRY SubClassFunc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
   return _OOHG_WndProcCtrl( hWnd, msg, wParam, lParam, lpfnOldWndProc );
}

HB_FUNC( INITRICHEDITBOX )
{
   HWND hwnd;
   HWND hwndRE = 0;
   int Style, StyleEx, Mask;

   StyleEx = WS_EX_CLIENTEDGE | _OOHG_RTL_Status( hb_parl( 9 ) );

   hwnd = HWNDparam( 1 );

   Style = ES_MULTILINE | ES_WANTRETURN | WS_CHILD | hb_parni( 7 );

   Mask = ENM_CHANGE | ENM_SELCHANGE | ENM_SCROLL;

   InitCommonControls();
   if ( LoadLibrary( "RichEd20.dll" ) )
   {
      hwndRE = CreateWindowEx( StyleEx, RICHEDIT_CLASS , (LPSTR) NULL,
              Style, hb_parni( 3 ), hb_parni( 4 ), hb_parni( 5 ), hb_parni( 6 ),
              hwnd, (HMENU) HWNDparam( 2 ), GetModuleHandle( NULL ), NULL );

      lpfnOldWndProc = (WNDPROC) SetWindowLongPtr( hwndRE, GWL_WNDPROC, (LONG_PTR) SubClassFunc );

      if( hb_parni( 8 ) != 0 )
      {
         SendMessage( hwndRE, EM_EXLIMITTEXT, ( WPARAM) 0, ( LPARAM ) hb_parni( 8 ) );
      }

      SendMessage( hwndRE, EM_SETEVENTMASK, 0, ( LPARAM ) Mask );
   }

   HWNDret( hwndRE );
}

HB_FUNC_STATIC( TEDITRICH_BACKCOLOR )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lBackColor, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         if( oSelf->lBackColor != -1 )
         {
            SendMessage( oSelf->hWnd, EM_SETBKGNDCOLOR, 0, oSelf->lBackColor );
         }
         else
         {
            SendMessage( oSelf->hWnd, EM_SETBKGNDCOLOR, 0, GetSysColor( COLOR_WINDOW ) );
         }
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

HB_FUNC_STATIC( TEDITRICH_FONTCOLOR )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   CHARFORMAT2 Format;

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lFontColor, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         memset( &Format, 0, sizeof( Format ) );
         Format.cbSize = sizeof( Format );
         Format.dwMask = CFM_COLOR;
         Format.crTextColor = ( ( oSelf->lFontColor != -1 ) ? (COLORREF) oSelf->lFontColor : GetSysColor( COLOR_WINDOWTEXT ) );

         SendMessage( oSelf->hWnd, EM_SETCHARFORMAT, (WPARAM) SCF_ALL, (LPARAM) &Format );

         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

struct StreamInfo {
   LONG lSize;
   LONG lRead;
   char *cBuffer;
   struct StreamInfo *pNext;
};

EDITSTREAMCALLBACK CALLBACK EditStreamCallbackIn( DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG *pcb )
{
   struct StreamInfo *si;
   LONG lMax;

   si = ( struct StreamInfo * ) dwCookie;

   if( si->lSize == si->lRead )
   {
      *pcb = 0;
   }
   else
   {
      lMax = si->lSize - si->lRead;
      if( cb < lMax )
      {
         lMax = cb;
      }
      memcpy( pbBuff, si->cBuffer + si->lRead, lMax );
      si->lRead += lMax;
      *pcb = lMax;
   }
   return 0;
}

HB_FUNC( RICHSTREAMIN )   // hWnd, cValue
{
   int iType = SF_RTF;
   EDITSTREAM es;
   struct StreamInfo si;

   si.lSize = hb_parclen( 2 );
   si.lRead = 0;
   si.cBuffer = ( char * ) hb_parc( 2 );

   es.dwCookie = ( DWORD_PTR ) &si;
   es.dwError = 0;
   es.pfnCallback = ( EDITSTREAMCALLBACK ) EditStreamCallbackIn;

   SendMessage( HWNDparam( 1 ), EM_STREAMIN, ( WPARAM ) iType, ( LPARAM ) &es );
}

EDITSTREAMCALLBACK CALLBACK EditStreamCallbackOut( DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG *pcb )
{
   struct StreamInfo *si;

   si = ( struct StreamInfo * ) dwCookie;

   if( cb == 0 )
   {
      *pcb = 0;
   }
   else
   {
      // Locates next available block
      while( si->lSize != 0 )
      {
         if( si->pNext )
         {
            si = si->pNext;
         }
         else
         {
            si->pNext = (struct StreamInfo *) hb_xgrab( sizeof( struct StreamInfo ) );
            si = si->pNext;
            si->lSize = 0;
            si->pNext = NULL;
         }
      }

      si->cBuffer = (char *) hb_xgrab( cb );
      memcpy( si->cBuffer, pbBuff, cb );
      si->lSize = cb;
      *pcb = cb;
   }
   return 0;
}

HB_FUNC( RICHSTREAMOUT )   // hWnd
{
   int iType = SF_RTF;
   EDITSTREAM es;
   struct StreamInfo *si, *si2;
   LONG lSize, lRead;
   char *cBuffer;

   si = (struct StreamInfo *) hb_xgrab( sizeof( struct StreamInfo ) );
   si->lSize = 0;
   si->pNext = NULL;

   es.dwCookie = ( DWORD_PTR ) si;
   es.dwError = 0;
   es.pfnCallback = ( EDITSTREAMCALLBACK ) EditStreamCallbackOut;

   SendMessage( HWNDparam( 1 ), EM_STREAMOUT, ( WPARAM ) iType, ( LPARAM ) &es );

   lSize = si->lSize;
   si2 = si->pNext;
   while( si2 )
   {
      lSize += si2->lSize;
      si2 = si2->pNext;
   }

   if( lSize == 0 )
   {
      hb_retc( "" );
      hb_xfree( si );
   }
   else
   {
      cBuffer = (char *) hb_xgrab( lSize );
      lRead = 0;
      while( si )
      {
         memcpy( cBuffer + lRead, si->cBuffer, si->lSize );
         hb_xfree( si->cBuffer );
         lRead += si->lSize;
         si2 = si;
         si = si->pNext;
         hb_xfree( si2 );
      }
      hb_retclen( cBuffer, lSize );
      hb_xfree( cBuffer );
   }
}

EDITSTREAMCALLBACK CALLBACK EditStreamCallbackFileIn( DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG *pcb )
{
   HANDLE hFile = (HANDLE) dwCookie;

   if( ReadFile( hFile, (LPVOID) pbBuff, cb, (LPDWORD) pcb, NULL ) )
   {
      return (EDITSTREAMCALLBACK) 0;
   }
   else
   {
      return (EDITSTREAMCALLBACK) -1;
   }
}

EDITSTREAMCALLBACK CALLBACK EditStreamCallbackFileOut( DWORD_PTR dwCookie, LPBYTE pbBuff, LONG cb, LONG *pcb )
{
   HANDLE hFile = (HANDLE) dwCookie;

   if( WriteFile( hFile, (LPVOID) pbBuff, cb, (LPDWORD) pcb, NULL ) )
   {
      return (EDITSTREAMCALLBACK) 0;
   }
   else
   {
      return (EDITSTREAMCALLBACK) -1;
   }
}

HB_FUNC( FILESTREAMIN )        // hWnd, cFile, nType
{
   HWND hwnd = HWNDparam( 1 );
   HANDLE hFile;
   EDITSTREAM es;
   long lFlag, lMode;

   switch( hb_parni( 3 ) )
   {
      case 1:
      {
         lFlag = SF_TEXT;
         lMode = TM_PLAINTEXT;
         break;
      }
      case 2:
      {
         lFlag = SF_RTF;
         lMode = TM_RICHTEXT;
         break;
      }
      case 3:
      {
         lFlag = SF_TEXT | SF_UNICODE;
         lMode = TM_PLAINTEXT;
         break;
      }
      case 4:
      {
         lFlag = ( CP_UTF8 << 16 ) | SF_USECODEPAGE | SF_TEXT;
         lMode = TM_PLAINTEXT;
         break;
      }
      case 5:
      {
         lFlag = ( CP_UTF8 << 16 ) | SF_USECODEPAGE | SF_RTF; ;
         lMode = TM_RICHTEXT;
         break;
      }
      case 6:
      {
         lFlag = ( CP_UTF7 << 16 ) | SF_USECODEPAGE | SF_TEXT; ;
         lMode = TM_PLAINTEXT;
         break;
      }
      default:
      {
         lFlag = SF_TEXT;
         lMode = TM_PLAINTEXT;
      }
   }

   if( ( hFile = CreateFile( hb_parc( 2 ), GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL ) ) == INVALID_HANDLE_VALUE )
   {
      hb_retl( FALSE );
   }

   es.dwCookie = (DWORD) hFile;
   es.dwError = 0;
   es.pfnCallback = (EDITSTREAMCALLBACK) EditStreamCallbackFileIn;

   SendMessage( hwnd, (UINT) EM_STREAMIN, (WPARAM) lFlag, (LPARAM) &es );
   SendMessage( hwnd, (UINT) EM_SETTEXTMODE, (WPARAM) lMode, 0 );

   CloseHandle( hFile );

   if( es.dwError )
   {
      hb_retl( FALSE );
   }
   else
   {
      hb_retl( TRUE );
   }
}

HB_FUNC( FILESTREAMOUT )       // hWnd, cFile, nType
{
   HWND hwnd = HWNDparam( 1 );
   HANDLE hFile;
   EDITSTREAM es;
   long lFlag;

   switch( hb_parni( 3 ) )
   {
      case 1:
      {
         lFlag = SF_TEXT;
         break;
      }
      case 2:
      {
         lFlag = SF_RTF;
         break;
      }
      case 3:
      {
         lFlag = SF_TEXT | SF_UNICODE;
         break;
      }
      case 4:
      {
         lFlag = ( CP_UTF8 << 16 ) | SF_USECODEPAGE | SF_TEXT;
         break;
      }
      case 5:
      {
         lFlag = ( CP_UTF8 << 16 ) | SF_USECODEPAGE | SF_RTF;
         break;
      }
      case 6:
      {
         lFlag = ( CP_UTF7 << 16 ) | SF_USECODEPAGE | SF_TEXT;
         break;
      }
      default:
      {
         lFlag = SF_TEXT;
      }
   }

   if( ( hFile = CreateFile( hb_parc( 2 ), GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL ) ) == INVALID_HANDLE_VALUE )
   {
      hb_retl( FALSE );
   }

   es.dwCookie = (DWORD) hFile;
   es.dwError = 0;
   es.pfnCallback = (EDITSTREAMCALLBACK) EditStreamCallbackFileOut;

   SendMessage( hwnd, EM_STREAMOUT, (WPARAM) lFlag, (LPARAM) &es );

   CloseHandle( hFile );

   if( es.dwError )
   {
      hb_retl( FALSE );
   }
   else
   {
      hb_retl( TRUE );
   }
}

#define s_Super s_TEdit

// -----------------------------------------------------------------------------
HB_FUNC_STATIC( TEDITRICH_EVENTS )   // METHOD Events( hWnd, nMsg, wParam, lParam ) CLASS TEditRich
// -----------------------------------------------------------------------------
{
   HWND hWnd      = HWNDparam( 1 );
   UINT message   = ( UINT )   hb_parni( 2 );
   WPARAM wParam  = ( WPARAM ) hb_parni( 3 );
   LPARAM lParam  = ( LPARAM ) hb_parnl( 4 );
   PHB_ITEM pSelf = hb_stackSelfItem();

   switch( message )
   {
      case WM_LBUTTONDBLCLK:
          HB_FUNCNAME( TEDITRICH_EVENTS2 )();
          break;

      case WM_KEYDOWN:
         if( ( GetWindowLongPtr( hWnd, GWL_STYLE ) & ES_READONLY ) == 0 )
         {
            HB_FUNCNAME( TEDITRICH_EVENTS2 )();
            break;
         }

      default:
         _OOHG_Send( pSelf, s_Super );
         hb_vmSend( 0 );
         _OOHG_Send( hb_param( -1, HB_IT_OBJECT ), s_Events );
         HWNDpush( hWnd );
         hb_vmPushLong( message );
         hb_vmPushNumInt( wParam );
         hb_vmPushNumInt( lParam );
         hb_vmSend( 4 );
         break;
   }
}

HB_FUNC_STATIC( TEDITRICH_SETSELECTIONTEXTCOLOR )       // METHOD SetSelectionTextColor( lColor ) CLASS TEditRich
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   CHARFORMAT2 Format;
   COLORREF clrColor;

   if( HB_ISNIL( 1 ) )
   {
      clrColor = ( ( oSelf->lFontColor == -1 ) ? GetSysColor( COLOR_WINDOWTEXT ) : (COLORREF) oSelf->lFontColor );
   }
   else
   {
      clrColor = (COLORREF) hb_parnl( 1 );
   }

   memset( &Format, 0, sizeof( Format ) );
   Format.cbSize = sizeof( Format );
   Format.dwMask = CFM_COLOR;
   Format.crTextColor = clrColor;

   SendMessage( oSelf->hWnd, EM_SETCHARFORMAT, (WPARAM) SCF_SELECTION, (LPARAM) &Format );
}

HB_FUNC_STATIC( TEDITRICH_SETSELECTIONBACKCOLOR )       // METHOD SetSelectionBackColor( lColor ) CLASS TEditRich
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   CHARFORMAT2 Format;
   COLORREF clrColor;

   if( HB_ISNIL( 1 ) )
   {
      clrColor = ( ( oSelf->lBackColor == -1 ) ? GetSysColor( COLOR_WINDOW ) : (COLORREF) oSelf->lBackColor );
   }
   else
   {
      clrColor = (COLORREF) hb_parnl( 1 );
   }

   memset( &Format, 0, sizeof( Format ) );
   Format.cbSize = sizeof( Format );
   Format.dwMask = CFM_BACKCOLOR;
   Format.crBackColor = clrColor;

   SendMessage( oSelf->hWnd, EM_SETCHARFORMAT, (WPARAM) SCF_SELECTION, (LPARAM) &Format );
}

HB_FUNC_STATIC( TEDITRICH_HIDESELECTION )       // METHOD HideSelection( lHide ) CLASS TEditRich
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   SendMessage( oSelf->hWnd, EM_HIDESELECTION, (WPARAM) ( hb_parl( 1 ) ? 1 : 0 ), 0 );
}

HB_FUNC( RICHEDIT_GETSELTEXT )

{
   GETTEXTLENGTHEX gtl;
   GETTEXTEX gte;
   char *cBuffer;

   gtl.flags = GTL_USECRLF | GTL_PRECISE | GTL_NUMCHARS;
   gtl.codepage = CP_ACP;

   gte.cb = SendMessage( HWNDparam( 1 ), EM_GETTEXTLENGTHEX, (WPARAM) &gtl, 0 ) + 1;
   gte.flags = GT_SELECTION | GT_USECRLF;
   gte.codepage = CP_ACP;
   gte.lpDefaultChar = NULL;
   gte.lpUsedDefChar = NULL;

   cBuffer = (char *) hb_xgrab( gte.cb );

   SendMessage( HWNDparam( 1 ), EM_GETSELTEXT, 0, (LPARAM) cBuffer );

   hb_retc( cBuffer );
   hb_xfree( cBuffer );
}

// -----------------------------------------------------------------------------
HB_FUNC_STATIC( TEDITRICH_GETCHARFROMPOS )           // METHOD GetCharFromPos( nRow, nCol ) CLASS TEditRich
// -----------------------------------------------------------------------------
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   POINTL pnt;

   pnt.x = hb_parni( 2 );
   pnt.y = hb_parni( 1 );

   hb_retni( SendMessage( oSelf->hWnd, EM_CHARFROMPOS, 0, (LPARAM) &pnt ) );        // zero-based index
}

// -----------------------------------------------------------------------------
HB_FUNC( GETFONTRTF )
// -----------------------------------------------------------------------------
// GetFontRTF( hWnd, nSel ) -> { cFontName, nFontSize, lBold, lItalic, nTextColor, lUnderline, lStrikeout, nCharset }
{
   CHARFORMAT  cF;
   long        PointSize;
   int         bold;
   int         Italic;
   int         Underline;
   int         StrikeOut;
   int         SelText;
   HWND        hWnd = HWNDparam( 1 );

   cF.cbSize = sizeof( CHARFORMAT );
   cF.dwMask = CFM_BOLD | CFM_ITALIC | CFM_UNDERLINE | CFM_SIZE;
   if( hb_parni( 2 ) > 0 )
   {
      SelText = SCF_SELECTION;
   }
   else
   {
      SelText = SCF_DEFAULT;
   }

   SendMessage( hWnd, EM_GETCHARFORMAT, (WPARAM) SelText, (LPARAM) &cF );

   PointSize = cF.yHeight / 20;

   bold = ( cF.dwEffects & CFE_BOLD ) ? 1 : 0;
   Italic = ( cF.dwEffects & CFE_ITALIC ) ? 1 : 0;
   Underline = ( cF.dwEffects & CFE_UNDERLINE ) ? 1 : 0;
   StrikeOut = ( cF.dwEffects & CFE_STRIKEOUT ) ? 1 : 0;

   hb_reta( 8 );
   HB_STORC( cF.szFaceName, -1, 1 );
   HB_STORNL3( (LONG) PointSize, -1, 2 );
   HB_STORL( bold, -1, 3 );
   HB_STORL( Italic, -1, 4 );
   HB_STORNL3( (LONG) cF.crTextColor, -1, 5 );
   HB_STORL( Underline, -1, 6 );
   HB_STORL( StrikeOut, -1, 7 );
   HB_STORNI( cF.bCharSet, -1, 8 );
}

// -----------------------------------------------------------------------------
HB_FUNC( SETFONTRTF )
// -----------------------------------------------------------------------------
// SetFontRTF( hWnd, nSel, cFontName, nFontSize, lBold, lItalic, nTextColor, lUnderline, lStrikeout, nMask )
// See https://msdn.microsoft.com/en-us/library/windows/desktop/bb788026(v=vs.85).aspx
// See https://msdn.microsoft.com/en-us/library/windows/desktop/bb774230(v=vs.85).aspx
// See https://msdn.microsoft.com/en-us/library/windows/desktop/bb787881(v=vs.85).aspx
{
   LRESULT     lResult;
   CHARFORMAT  cF;
   DWORD       Mask;
   DWORD       Effects = 0;
   int         SelText = SCF_SELECTION;
   HWND        hWnd = HWNDparam( 1 );

   cF.cbSize = sizeof( CHARFORMAT );
   Mask = SendMessage( hWnd, EM_GETCHARFORMAT, (WPARAM) SelText, (LPARAM) &cF );

   if( hb_parni( 10 ) > 0 )
   {
      Mask = hb_parni( 10 );
   }

   if( hb_parni( 2 ) > 0 )
   {
      SelText = SCF_SELECTION | SCF_WORD;
   }

   if( hb_parni( 2 ) < 0 )
   {
      SelText = SCF_ALL;
   }

   if( hb_parl( 5 ) )
   {
      Effects = Effects | CFE_BOLD;
   }

   if( hb_parl( 6 ) )
   {
      Effects = Effects | CFE_ITALIC;
   }

   if( hb_parl( 8 ) )
   {
      Effects = Effects | CFE_UNDERLINE;
   }

   if( hb_parl( 9 ) )
   {
      Effects = Effects | CFE_STRIKEOUT;
   }

   cF.dwMask = Mask;
   cF.dwEffects = Effects;
   if( hb_parnl( 4 ) )
   {
      cF.yHeight = hb_parnl( 4 ) * 20;
   }

   cF.crTextColor = hb_parnl( 7 );

   if( strlen( hb_parc( 3 ) ) )
   {
      lstrcpy( cF.szFaceName, hb_parc( 3 ) );
   }

   lResult = SendMessage( hWnd, EM_SETCHARFORMAT, (WPARAM) SelText, (LPARAM) &cF );

   if( lResult )
   {
      hb_retl( TRUE );
   }
   else
   {
      hb_retl( FALSE );
   }
}

#pragma ENDDUMP


FUNCTION TEditRich_Events2( hWnd, nMsg, wParam, lParam )

   Local Self := QSelf()
   Local cText, lRet

   If nMsg == WM_KEYDOWN .AND. wParam == VK_Z .AND. ( GetKeyFlagState() == MOD_CONTROL .OR. GetKeyFlagState() == MOD_CONTROL + MOD_SHIFT )

      cText := ::Value
      ::Value := ::xUndo
      ::xUndo := cText
      Return 1

   ElseIf nMsg == WM_LBUTTONDBLCLK
      lRet := ::DoEventMouseCoords( ::OnDblClick, "DBLCLICK" )
      If HB_IsLogical( lRet ) .AND. lRet
         If ::lDefault
            // Do default action: select word
            Return Nil
         Else
            // Prevent default action
            Return 1
         EndIf
      EndIf

   Endif

   Return ::Super:Events( hWnd, nMsg, wParam, lParam )

METHOD Events_Notify( wParam, lParam ) CLASS TEditRich

   Local nNotify := GetNotifyCode( lParam )

   If nNotify == EN_SELCHANGE
      If ! ::lSelChanging
         ::lSelChanging := .T.
         ::DoEvent( ::OnSelChange, "SELCHANGE" )
         ::lSelChanging := .F.
      EndIf
   EndIf

   Return ::Super:Events_Notify( wParam, lParam )

METHOD GetSelText( lTranslate ) CLASS TEditRich

   Local cSelText := RichEdit_GetSelText( ::hWnd )

   If HB_IsLogical( lTranslate ) .AND. lTranslate
     cSelText := StrTran( cSelText, Chr(13), Chr(13) + Chr(10) )
   EndIf

   Return cSelText

METHOD MaxLength( nLen ) CLASS TEditRich

   If HB_IsNumeric( nLen )
      SendMessage( ::hWnd, EM_EXLIMITTEXT, 0, nLen )
   EndIf

   Return SendMessage( ::hWnd, EM_GETLIMITTEXT, 0, 0 )

METHOD GetLastVisibleLine CLASS TEditRich

   LOCAL aRect, nChar

   aRect := ::GetRect()            // top, left, bottom, right
   nChar := ::GetCharFromPos( aRect[3] - 2, aRect[2] + 1 )

   Return ::GetLineFromChar( nChar )
