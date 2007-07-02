/*
 * $Id: h_windows.prg,v 1.135 2007-07-02 03:37:34 guerra000 Exp $
 */
/*
 * ooHG source code:
 * PRG Windows handling functions
 *
 * Copyright 2005 Vicente Guerra <vicente@guerra.com.mx>
 * www - http://www.guerra.com.mx
 *
 * Portions of this code are copyrighted by the Harbour MiniGUI library.
 * Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
 *
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
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
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
 *
 */
/*----------------------------------------------------------------------------
 MINIGUI - Harbour Win32 GUI library source code

 Copyright 2002-2005 Roberto Lopez <roblez@ciudad.com.ar>
 http://www.geocities.com/harbour_minigui/

 This program is free software; you can redistribute it and/or modify it under
 the terms of the GNU General Public License as published by the Free Software
 Foundation; either version 2 of the License, or (at your option) any later
 version.

 This program is distributed in the hope that it will be useful, but WITHOUT
 ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

 You should have received a copy of the GNU General Public License along with
 this software; see the file COPYING. If not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA (or
 visit the web site http://www.gnu.org/).

 As a special exception, you have permission for additional uses of the text
 contained in this release of Harbour Minigui.

 The exception is that, if you link the Harbour Minigui library with other
 files to produce an executable, this does not by itself cause the resulting
 executable to be covered by the GNU General Public License.
 Your use of that executable is in no way restricted on account of linking the
 Harbour-Minigui library code into it.

 Parts of this project are based upon:

	"Harbour GUI framework for Win32"
 	Copyright 2001 Alexander S.Kresin <alex@belacy.belgorod.su>
 	Copyright 2001 Antonio Linares <alinares@fivetech.com>
	www - http://www.harbour-project.org

	"Harbour Project"
	Copyright 1999-2003, http://www.harbour-project.org/
---------------------------------------------------------------------------*/

#include "oohg.ch"
#include "i_windefs.ch"
#include "common.ch"
#include "error.ch"

STATIC _OOHG_aFormhWnd := {}, _OOHG_aFormObjects := {}
STATIC _OOHG_aEventInfo := {}        // Event's stack
STATIC _OOHG_UserWindow := nil       // User's window
STATIC _OOHG_InteractiveClose := 1   // Interactive close
STATIC _OOHG_MessageLoops := {}      // Message loops
STATIC _OOHG_ActiveModal := {}       // Modal windows' stack
STATIC _OOHG_DialogCancelled := .F.  //
STATIC _OOHG_HotKeys := {}           // Application-wide hot keys
STATIC _OOHG_ActiveForm := {}        // Forms under creation
STATIC _OOHG_bKeyDown := nil         // Application-wide WM_KEYDOWN handler

#include "hbclass.ch"

// C static variables
#pragma BEGINDUMP

#ifndef WINVER
   #define WINVER 0x0500
#endif
#if ( WINVER < 0x0500 )
   #undef WINVER
   #define WINVER 0x0500
#endif

#ifndef _WIN32_WINNT
   #define _WIN32_WINNT 0x0500
#endif
#if ( _WIN32_WINNT < 0x0500 )
   #undef _WIN32_WINNT
   #define _WIN32_WINNT 0x0500
#endif

#include "hbapi.h"
#include "hbapiitm.h"
#include "hbvm.h"
#include "hbstack.h"
#include <windows.h>
#include <commctrl.h>
#include <olectl.h>
#include "../include/oohg.h"

#ifdef HB_ITEM_NIL
   #define hb_dynsymSymbol( pDynSym )        ( ( pDynSym )->pSymbol )
#endif

int  _OOHG_ShowContextMenus = 1;      //
int  _OOHG_GlobalRTL = 0;             // Force RTL functionality
int  _OOHG_NestedSameEvent = 0;       // Allows to nest an event currently performed (i.e. CLICK button)
LONG _OOHG_TooltipBackcolor = -1;     // Tooltip's backcolor
LONG _OOHG_TooltipForecolor = -1;     // Tooltip's forecolor
int  _OOHG_MouseCol = 0;              // Mouse's column
int  _OOHG_MouseRow = 0;              // Mouse's row
PHB_ITEM _OOHG_LastSelf = NULL;

void _OOHG_SetMouseCoords( PHB_ITEM pSelf, int iCol, int iRow )
{
   PHB_ITEM pSelf2;

   pSelf2 = hb_itemNew( NULL );
   hb_itemCopy( pSelf2, pSelf );

   _OOHG_Send( pSelf2, s_ColMargin );
   hb_vmSend( 0 );
   _OOHG_MouseCol = iCol - hb_parni( -1 );

   _OOHG_Send( pSelf2, s_RowMargin );
   hb_vmSend( 0 );
   _OOHG_MouseRow = iRow - hb_parni( -1 );

   hb_itemRelease( pSelf2 );
}

#pragma ENDDUMP

*------------------------------------------------------------------------------*
CLASS TWindow
*------------------------------------------------------------------------------*
   DATA hWnd       INIT 0
   DATA aControlInfo INIT { CHR( 0 ) }
   DATA Name       INIT ""
   DATA Type       INIT ""
   DATA Parent     INIT nil
   DATA nRow       INIT 0
   DATA nCol       INIT 0
   DATA nWidth     INIT 0
   DATA nHeight    INIT 0
   DATA Active     INIT .F.
   DATA cFontName  INIT ""
   DATA nFontSize  INIT 0
   DATA Bold       INIT .F.
   DATA Italic     INIT .F.
   DATA Underline  INIT .F.
   DATA Strikeout  INIT .F.
   DATA RowMargin  INIT 0
   DATA ColMargin  INIT 0
   DATA Container           INIT nil
   DATA ContainerhWndValue  INIT nil
   DATA lRtl                INIT .F.
   DATA lVisible            INIT .T.
   DATA ContextMenu         INIT nil
   DATA Cargo               INIT nil
   DATA lEnabled            INIT .T.
   DATA aControls           INIT {}
   DATA aControlsNames      INIT {}
   DATA WndProc             INIT nil
   DATA OverWndProc         INIT nil
   DATA lInternal           INIT .T.
   DATA lForm               INIT .F.
   DATA lReleasing          INIT .F.

   DATA OnClick             INIT nil
   DATA OnGotFocus          INIT nil
   DATA OnLostFocus         INIT nil
   DATA OnMouseDrag         INIT nil
   DATA OnMouseMove         INIT nil
   DATA aKeys               INIT {}  // { Id, Mod, Key, Action }   Application-controlled hotkeys
   DATA aHotKeys            INIT {}  // { Id, Mod, Key, Action }   OperatingSystem-controlled hotkeys
   DATA bKeyDown            INIT nil     // WM_KEYDOWN handler
   DATA NestedClick         INIT .F.
   DATA HScrollBar          INIT nil
   DATA VScrollBar          INIT nil

   DATA DefBkColorEdit      INIT nil

   METHOD SethWnd
   METHOD Release
   METHOD StartInfo
   METHOD SetFocus
   METHOD ImageList           SETGET
   METHOD BrushHandle         SETGET
   METHOD FontHandle          SETGET
   METHOD FontColor           SETGET
   METHOD BackColor           SETGET
   METHOD FontColorSelected   SETGET
   METHOD BackColorSelected   SETGET
   METHOD Caption             SETGET
   METHOD Events

   METHOD Object              BLOCK { |Self| Self }
   METHOD Enabled             SETGET
   METHOD Enable              BLOCK { |Self| ::Enabled := .T. }
   METHOD Disable             BLOCK { |Self| ::Enabled := .F. }
   METHOD Click               BLOCK { |Self| ::DoEvent( ::OnClick ) }
   METHOD TabStop             SETGET
   METHOD Style               SETGET
   METHOD RTL                 SETGET
   METHOD Action              SETGET
   METHOD Print
   METHOD AddControl
   METHOD DeleteControl
   METHOD SearchParent
   METHOD ParentDefaults

   METHOD Events_Size         BLOCK { || nil }
   METHOD Events_VScroll      BLOCK { || nil }
   METHOD Events_HScroll      BLOCK { || nil }
   METHOD Events_Enter        BLOCK { || nil }

   ERROR HANDLER Error
   METHOD Control

   METHOD HotKey                // OperatingSystem-controlled hotkeys
   METHOD SetKey                // Application-controlled hotkeys
   METHOD LookForKey
   METHOD Visible             SETGET
   METHOD Show                BLOCK { |Self| ::Visible := .T. }
   METHOD Hide                BLOCK { |Self| ::Visible := .F. }
   METHOD ForceHide           BLOCK { |Self| HideWindow( ::hWnd ) }
   METHOD ReDraw              BLOCK { |Self| RedrawWindow( ::hWnd ) }

   METHOD ContainerVisible    BLOCK { |Self| ::lVisible .AND. IF( ::Container != NIL, ::Container:ContainerVisible, .T. ) }
   METHOD ContainerReleasing  BLOCK { |Self| ::lReleasing .OR. IF( ::Container != NIL, ::Container:ContainerReleasing, IF( ::Parent != NIL, ::Parent:ContainerReleasing, .F. ) ) }

   // Specific HACKS :(
   METHOD SetSplitBox         BLOCK { || .F. }
   METHOD SetSplitBoxInfo     BLOCK { |Self,a,b,c,d| if( ::Container != nil, ::Container:SetSplitBox( a,b,c,d ), .F. ) }
ENDCLASS

#pragma BEGINDUMP

HB_FUNC_STATIC( TWINDOW_SETHWND )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( hb_pcount() >= 1 && ISNUM( 1 ) )
   {
      oSelf->hWnd = HWNDparam( 1 );
   }

   HWNDret( oSelf->hWnd );
}

HB_FUNC_STATIC( TWINDOW_RELEASE )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   // ImageList
   if( ValidHandler( oSelf->ImageList ) )
   {
      ImageList_Destroy( oSelf->ImageList );
      oSelf->ImageList = 0;
   }

   // Auxiliar Buffer
   if( oSelf->AuxBuffer )
   {
      hb_xfree( oSelf->AuxBuffer );
      oSelf->AuxBuffer = NULL;
      oSelf->AuxBufferLen = 0;
   }

   // Brush handle
   if( ValidHandler( oSelf->BrushHandle ) )
   {
      DeleteObject( oSelf->BrushHandle );
      oSelf->BrushHandle = NULL;
   }

   // Context menu
   _OOHG_Send( pSelf, s_ContextMenu );
   hb_vmSend( 0 );
   if( hb_param( -1, HB_IT_OBJECT ) )
   {
      _OOHG_Send( hb_param( -1, HB_IT_OBJECT ), s_Release );
      hb_vmSend( 0 );
      _OOHG_Send( pSelf, s__ContextMenu );
      hb_vmPushNil();
      hb_vmSend( 1 );
   }

   // ::hWnd := -1
   oSelf->hWnd = ( HWND )( ~0 );
   _OOHG_Send( pSelf, s__hWnd );
   HWNDpush( ~0 );
   hb_vmSend( 1 );
}

HB_FUNC_STATIC( TWINDOW_STARTINFO )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   oSelf->hWnd = HWNDparam( 1 );

   oSelf->lFontColor = -1;
   oSelf->lBackColor = -1;
   oSelf->lFontColorSelected = -1;
   oSelf->lBackColorSelected = -1;
   oSelf->lOldBackColor = -1;
   oSelf->lUseBackColor = -1;

   // HACK! Latest created control... Needed for WM_MEASUREITEM :(
   if( ! _OOHG_LastSelf )
   {
      _OOHG_LastSelf = hb_itemNew( NULL );
   }
   hb_itemCopy( _OOHG_LastSelf, pSelf );
}

HB_FUNC_STATIC( TWINDOW_SETFOCUS )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   PHB_ITEM pReturn;

   if( ValidHandler( oSelf->hWnd ) )
   {
      SetFocus( oSelf->hWnd );
   }

   pReturn = hb_itemNew( NULL );
   hb_itemCopy( pReturn, pSelf );
   hb_itemReturn( pReturn );
   hb_itemRelease( pReturn );
}

HB_FUNC_STATIC( TWINDOW_IMAGELIST )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( hb_pcount() >= 1 && ISNUM( 1 ) )
   {
      oSelf->ImageList = ( HIMAGELIST ) hb_parnl( 1 );
   }

   HWNDret( oSelf->ImageList );
}

HB_FUNC_STATIC( TWINDOW_BRUSHHANDLE )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( hb_pcount() >= 1 && ISNUM( 1 ) )
   {
      oSelf->BrushHandle = ( HBRUSH ) HWNDparam( 1 );
   }

   HWNDret( oSelf->BrushHandle );
}

HB_FUNC_STATIC( TWINDOW_FONTHANDLE )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( hb_pcount() >= 1 && ISNUM( 1 ) )
   {
      oSelf->hFontHandle = ( HFONT ) HWNDparam( 1 );
   }

   HWNDret( oSelf->hFontHandle );
}

HB_FUNC_STATIC( TWINDOW_FONTCOLOR )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lFontColor, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

HB_FUNC_STATIC( TWINDOW_BACKCOLOR )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lBackColor, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

HB_FUNC_STATIC( TWINDOW_FONTCOLORSELECTED )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lFontColorSelected, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

HB_FUNC_STATIC( TWINDOW_BACKCOLORSELECTED )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lBackColorSelected, ( hb_pcount() >= 1 ) ) )
   {
      if( ValidHandler( oSelf->hWnd ) )
      {
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}

HB_FUNC( TWINDOW_CAPTION )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );
   int iLen;
   LPTSTR cText;

   if( ISCHAR( 1 ) )
   {
      SetWindowText( oSelf->hWnd, ( LPCTSTR ) hb_parc( 1 ) );
   }

   iLen = GetWindowTextLength( oSelf->hWnd ) + 1;
   cText = ( LPTSTR ) hb_xgrab( iLen );
   GetWindowText( oSelf->hWnd, cText, iLen );
   hb_retc( cText );
   hb_xfree( cText );
}

HB_FUNC_STATIC( TWINDOW_EVENTS )
{
   HWND hWnd      = HWNDparam( 1 );
   UINT message   = ( UINT )   hb_parni( 2 );
   WPARAM wParam  = ( WPARAM ) hb_parni( 3 );
   LPARAM lParam  = ( LPARAM ) hb_parnl( 4 );
   PHB_ITEM pSelf = hb_stackSelfItem();

   switch( message )
   {
      case WM_CTLCOLORSTATIC:
         _OOHG_Send( GetControlObjectByHandle( ( HWND ) lParam ), s_Events_Color );
         hb_vmPushLong( wParam );
         hb_vmPushLong( GetSysColor( COLOR_3DFACE ) );
         hb_vmSend( 2 );
         break;

      case WM_CTLCOLOREDIT:
      case WM_CTLCOLORLISTBOX:
         _OOHG_Send( GetControlObjectByHandle( ( HWND ) lParam ), s_Events_Color );
         hb_vmPushLong( wParam );
         hb_vmPushLong( GetSysColor( COLOR_WINDOW ) );
         hb_vmSend( 2 );
         break;

      case WM_NOTIFY:
         _OOHG_Send( GetControlObjectByHandle( ( ( NMHDR FAR * ) lParam )->hwndFrom ), s_Events_Notify );
         hb_vmPushLong( wParam );
         hb_vmPushLong( lParam );
         hb_vmSend( 2 );
         break;

      case WM_COMMAND:
         if( wParam == 1 )
         {
            // Enter key
            _OOHG_Send( GetControlObjectByHandle( GetFocus() ), s_Events_Enter );
            hb_vmSend( 0 );
            break;
         }
         else
         {
            PHB_ITEM pControl, pOnClick;
            BOOL bClicked = 0;

            pControl = hb_itemNew( NULL );
            hb_itemCopy( pControl, GetControlObjectById( LOWORD( wParam ) ) );
            _OOHG_Send( pControl, s_Id );
            hb_vmSend( 0 );
            if( hb_parni( -1 ) != 0 )
            {
               // By Id
               // From MENU
               _OOHG_Send( pControl, s_NestedClick );
               hb_vmSend( 0 );
               if( ! hb_parl( -1 ) )
               {
                  _OOHG_Send( pControl, s__NestedClick );
                  hb_vmPushLogical( ! _OOHG_NestedSameEvent );
                  hb_vmSend( 1 );

                  _OOHG_Send( pControl, s_OnClick );
                  hb_vmSend( 0 );
                  if( hb_param( -1, HB_IT_BLOCK ) )
                  {
                     pOnClick = hb_itemNew( NULL );
                     hb_itemCopy( pOnClick, hb_param( -1, HB_IT_ANY ) );
                     _OOHG_Send( pControl, s_DoEvent );
                     hb_vmPush( pOnClick );
                     hb_vmSend( 1 );
                     hb_itemRelease( pOnClick );
                     bClicked = 1;
                  }

                  _OOHG_Send( pControl, s__NestedClick );
                  hb_vmPushLogical( 0 );
                  hb_vmSend( 1 );
               }
            }
            else
            {
               hb_itemCopy( pControl, GetControlObjectByHandle( ( HWND ) lParam ) );
               _OOHG_Send( pControl, s_hWnd );
               hb_vmSend( 0 );
               if( ValidHandler( HWNDparam( -1 ) ) )
               {
                  // By handle
                  _OOHG_Send( pControl, s_Events_Command );
                  hb_vmPushLong( wParam );
                  hb_vmSend( 1 );
                  hb_itemRelease( pControl );   // There's a break!
                  break;
               }
//               else
//               {
//                  if( HIWORD( wParam ) == 1 )
//                  {
//                     _OOHG_Send( pControl, s_Events_Accelerator );
//                     hb_vmPushLong( wParam );
//                     hb_vmSend( 1 );
//                     break;
//                  }
//               }
            }
            hb_itemRelease( pControl );
            if( bClicked )
            {
               hb_retni( 1 );
            }
            else
            {
               hb_ret();
            }
         }
         break;

      case WM_TIMER:
         {
            PHB_ITEM pControl, pOnClick;

            pControl = hb_itemNew( NULL );
            hb_itemCopy( pControl, GetControlObjectById( LOWORD( wParam ) ) );
            pOnClick = hb_itemNew( NULL );
            _OOHG_Send( pControl, s_OnClick );
            hb_vmSend( 0 );
            hb_itemCopy( pOnClick, hb_param( -1, HB_IT_ANY ) );
            _OOHG_Send( pControl, s_DoEvent );
            hb_vmPush( pOnClick );
            hb_vmSend( 1 );
            hb_itemRelease( pOnClick );
            hb_itemRelease( pControl );
         }
         hb_ret();
         break;

      case WM_DRAWITEM:
         _OOHG_Send( GetControlObjectByHandle( ( ( LPDRAWITEMSTRUCT ) lParam )->hwndItem ), s_Events_DrawItem );
         hb_vmPushLong( lParam );
         hb_vmSend( 1 );
         break;

      case WM_MEASUREITEM:
         if( wParam )
         {
            _OOHG_Send( GetControlObjectById( ( LONG ) ( ( ( LPMEASUREITEMSTRUCT ) lParam )->CtlID ) ), s_Events_MeasureItem );
         }
         else
         {
            _OOHG_Send( _OOHG_LastSelf, s_Events_MeasureItem );
         }
         hb_vmPushLong( lParam );
         hb_vmSend( 1 );
         break;

      case WM_CONTEXTMENU:
         if( _OOHG_ShowContextMenus )
         {
            PHB_ITEM pControl, pContext;

            // Sets mouse coords
            _OOHG_SetMouseCoords( pSelf, LOWORD( lParam ), HIWORD( lParam ) );

            SetFocus( ( HWND ) wParam );
            pControl = GetControlObjectByHandle( ( HWND ) wParam );

            // Check if control have context menu
            _OOHG_Send( pControl, s_ContextMenu );
            hb_vmSend( 0 );
            pContext = hb_param( -1, HB_IT_OBJECT );
            if( ! pContext )
            {
               // TODO: Check for CONTEXTMENU at container control...

               // Check if form have context menu
               _OOHG_Send( pSelf, s_ContextMenu );
               hb_vmSend( 0 );
               pContext = hb_param( -1, HB_IT_OBJECT );
            }

            // If there's a context menu, show it
            if( pContext )
            {

               // HMENU
               _OOHG_Send( pContext, s_Activate );
               hb_vmPushLong( HIWORD( lParam ) );
               hb_vmPushLong( LOWORD( lParam ) );
               hb_vmSend( 2 );
               hb_retni( 1 );
            }
            else
            {
               hb_ret();
            }
         }
         else
         {
            hb_ret();
         }
         break;

      case WM_MENURBUTTONUP:
         {
            PHB_ITEM pMenu;
            MENUITEMINFO MenuItemInfo;
            POINT Point;

            pMenu = hb_itemNew( NULL );
            hb_itemCopy( pMenu, GetControlObjectByHandle( ( HWND ) lParam ) );
            _OOHG_Send( pMenu, s_hWnd );
            hb_vmSend( 0 );
            if( ValidHandler( HWNDparam( -1 ) ) )
            {
               memset( &MenuItemInfo, 0, sizeof( MenuItemInfo ) );
               MenuItemInfo.cbSize = sizeof( MenuItemInfo );
               MenuItemInfo.fMask = MIIM_ID | MIIM_SUBMENU;
               GetMenuItemInfo( ( HMENU ) lParam, wParam, MF_BYPOSITION, &MenuItemInfo );
               if( MenuItemInfo.hSubMenu )
               {
                  hb_itemCopy( pMenu, GetControlObjectByHandle( ( HWND ) MenuItemInfo.hSubMenu ) );
               }
               else
               {
                  hb_itemCopy( pMenu, GetControlObjectById( MenuItemInfo.wID ) );
               }
               _OOHG_Send( pMenu, s_ContextMenu );
               hb_vmSend( 0 );
               if( hb_param( -1, HB_IT_OBJECT ) )
               {
                  hb_itemCopy( pMenu, hb_param( -1, HB_IT_OBJECT ) );
                  GetCursorPos( &Point );
                  // HMENU
                  _OOHG_Send( pMenu, s_hWnd );
                  hb_vmSend( 0 );
                  TrackPopupMenuEx( ( HMENU ) HWNDparam( -1 ), TPM_RECURSE, Point.x, Point.y, hWnd, 0 );
                  PostMessage( hWnd, WM_NULL, 0, 0 );
               }
            }
            hb_itemRelease( pMenu );
            hb_ret();
         }
         break;

      case WM_HSCROLL:
         if( lParam )
         {
            _OOHG_Send( GetControlObjectByHandle( ( HWND ) lParam ), s_Events_HScroll );
            hb_vmPushLong( wParam );
            hb_vmSend( 1 );
         }
         else
         {
            _OOHG_Send( pSelf, s_Events_HScroll );
            hb_vmPushLong( wParam );
            hb_vmSend( 1 );
         }
         break;

      case WM_VSCROLL:
         if( lParam )
         {
            _OOHG_Send( GetControlObjectByHandle( ( HWND ) lParam ), s_Events_VScroll );
            hb_vmPushLong( wParam );
            hb_vmSend( 1 );
         }
         else
         {
            _OOHG_Send( pSelf, s_Events_VScroll );
            hb_vmPushLong( wParam );
            hb_vmSend( 1 );
         }
         break;

      default:
         _OOHG_Send( pSelf, s_WndProc );
         hb_vmSend( 0 );
         if( hb_param( -1, HB_IT_BLOCK ) )
         {
            hb_vmPushSymbol( &hb_symEval );
            hb_vmPush( hb_param( -1, HB_IT_BLOCK ) );
            HWNDpush( hWnd );
            hb_vmPushLong( message );
            hb_vmPushLong( wParam );
            hb_vmPushLong( lParam );
            hb_vmPush( pSelf );
            hb_vmDo( 5 );
         }
         else
         {
            hb_ret();
         }
         break;
   }
}

#pragma ENDDUMP

*------------------------------------------------------------------------------*
METHOD Enabled( lEnabled ) CLASS TWindow
*------------------------------------------------------------------------------*
   IF VALTYPE( lEnabled ) == "L"
      IF lEnabled .AND. ( ::Container == NIL .OR. ::Container:Enabled )
         EnableWindow( ::hWnd )
      ELSE
         DisableWindow( ::hWnd )
      ENDIF
      ::lEnabled := lEnabled
   ENDIF
RETURN ::lEnabled

*------------------------------------------------------------------------------*
METHOD TabStop( lTabStop ) CLASS TWindow
*------------------------------------------------------------------------------*
   IF VALTYPE( lTabStop ) == "L"
      WindowStyleFlag( ::hWnd, WS_TABSTOP, IF( lTabStop, WS_TABSTOP, 0 ) )
   ENDIF
RETURN ( WindowStyleFlag( ::hWnd, WS_TABSTOP ) != 0 )

*------------------------------------------------------------------------------*
METHOD Style( nStyle ) CLASS TWindow
*------------------------------------------------------------------------------*
   IF VALTYPE( nStyle ) == "N"
      SetWindowStyle( ::hWnd, nStyle )
   ENDIF
RETURN GetWindowStyle( ::hWnd )

*------------------------------------------------------------------------------*
METHOD RTL( lRTL ) CLASS TWindow
*------------------------------------------------------------------------------*
   If ValType( lRTL ) == "L"
      _UpdateRTL( ::hWnd, lRtl )
      ::lRtl := lRtl
   EndIf
Return ::lRtl

*------------------------------------------------------------------------------*
METHOD Action( bAction ) CLASS TWindow
*------------------------------------------------------------------------------*
   If PCount() > 0
      ::OnClick := bAction
   EndIf
Return ::OnClick

*-----------------------------------------------------------------------------*
METHOD Print( y, x, y1, x1 ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local myobject, cWork
   cWork := '_oohg_t' + alltrim( str( int( random( 999999 ) ) ) ) + '.bmp'
   do while file( cWork )
      cWork := '_oohg_t' + alltrim( str( int( random( 999999 ) ) ) ) + '.bmp'
   enddo

   DEFAULT y1    TO 44
   DEFAULT x1    TO 110
   DEFAULT x    TO 1
   DEFAULT y    TO 1

   bringwindowtotop( ::hWnd )

   WNDCOPY( ::hWnd, .F., cWork ) //// save as BMP

   myobject:= Tprint()
   myobject:init()
   myobject:selprinter(.T. , .T. , .T.  )  /// select,preview,landscape
   if myobject:lprerror
      myobject:release()
      return nil
   endif
   myobject:begindoc("ooHG printing" )
   myobject:beginpage()
   myobject:printimage(y,x,y1,x1,cwork)
   myobject:endpage()
   myobject:enddoc()
   myobject:release()
   release myobject
   FErase( cWork )
return nil

*-----------------------------------------------------------------------------*
METHOD AddControl( oControl ) CLASS TWindow
*-----------------------------------------------------------------------------*
   AADD( ::aControls,      oControl )
   AADD( ::aControlsNames, UPPER( ALLTRIM( oControl:Name ) ) + CHR( 255 ) )
Return oControl

*-----------------------------------------------------------------------------*
METHOD DeleteControl( oControl ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local nPos
   nPos := aScan( ::aControlsNames, UPPER( ALLTRIM( oControl:Name ) ) + CHR( 255 ) )
   IF nPos > 0
      _OOHG_DeleteArrayItem( ::aControls,      nPos )
      _OOHG_DeleteArrayItem( ::aControlsNames, nPos )
   ENDIF
Return oControl

*-----------------------------------------------------------------------------*
METHOD SearchParent( uParent ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local nPos
   If ValType( uParent ) $ "CM" .AND. ! Empty( uParent )
      If ! _IsWindowDefined( uParent )
         MsgOOHGError( "Window: "+ uParent + " is not defined. Program terminated." )
      Else
         uParent := GetFormObject( uParent )
      Endif
   EndIf

   If ! ::lInternal
      // Search form's parent
      If ValType( uParent ) != "O"
         uParent := nil
         // Checks _OOHG_UserWindow
         If _OOHG_UserWindow != NIL .AND. ValidHandler( _OOHG_UserWindow:hWnd ) .AND. ascan( _OOHG_aFormhWnd, _OOHG_UserWindow:hWnd ) > 0
            uParent := _OOHG_UserWindow
         Else
            // Checks _OOHG_ActiveModal
            nPos := RASCAN( _OOHG_ActiveModal, { |o| ValidHandler( o:hWnd ) .AND. ascan( _OOHG_aFormhWnd, o:hWnd ) > 0 } )
            If nPos > 0
               uParent := _OOHG_ActiveModal[ nPos ]
            Else
               // Checks any active window
               nPos := RASCAN( _OOHG_aFormObjects, { |o| o:Active .AND. ValidHandler( o:hWnd ) .AND. ! o:lInternal } )
               If nPos > 0
                  uParent := _OOHG_aFormObjects[ nPos ]
               Else
                  // Checks _OOHG_ActiveForm
                  nPos := RASCAN( _OOHG_ActiveForm, { |o| ValidHandler( o:hWnd ) .AND. ! o:lInternal .AND. ascan( _OOHG_aFormhWnd, o:hWnd ) > 0 } )
                  If nPos > 0
                     uParent := _OOHG_ActiveForm[ nPos ]
                  Else
                     uParent := GetFormObjectByHandle( GetActiveWindow() )
                     If ! ValidHandler( uParent:hWnd ) .OR. ! uParent:Active
                        If _OOHG_Main != nil
                           uParent := _OOHG_Main
                        Else
                           // Not mandatory MAIN
                           // NO PARENT DETECTED!
                           uParent := nil
                        EndIf
                     EndIf
                  EndIf
               Endif
            Endif
         EndIf
      EndIf

   Else
      // Searchs control's parent
      If ValType( uParent ) != "O"
         If LEN( _OOHG_ActiveForm ) > 0
            uParent := ATAIL( _OOHG_ActiveForm )
         ElseIf len( _OOHG_ActiveFrame ) > 0
            uParent := ATAIL( _OOHG_ActiveFrame )
         Else
            MsgOOHGError( "Window: No window name specified. Program terminated.")
         EndIf
      EndIf

      // NOTE: For INTERNALs, sets ::Parent and ::Container
      // Checks if parent is a form or container
      If uParent:lForm
         ::Parent := uParent
         // Checks for an open "control container" structure in the specified parent form
         nPos := 0
         AEVAL( _OOHG_ActiveFrame, { |o,i| IF( o:Parent:hWnd == ::Parent:hWnd, nPos := i, ) } )
         If nPos > 0
            ::Container := _OOHG_ActiveFrame[ nPos ]
         EndIf
      Else
         ::Container := uParent
         ::Parent := ::Container:Parent
      EndIf

   EndIf
Return uParent

#ifndef __XHARBOUR__
STATIC FUNCTION RASCAN( aSource, bCode )
LOCAL nPos
   nPos := LEN( aSource )
   DO WHILE nPos > 0 .AND. ! EVAL( bCode, aSource[ nPos ], nPos )
      nPos--
   ENDDO
RETURN nPos
#endif

*-----------------------------------------------------------------------------*
METHOD ParentDefaults( cFontName, nFontSize, uFontColor ) CLASS TWindow
*-----------------------------------------------------------------------------*
   // Font Name:
   If ValType( cFontName ) == "C" .AND. ! EMPTY( cFontName )
      // Specified font
      ::cFontName := cFontName
   ElseIf ValType( ::cFontName ) == "C" .AND. ! Empty( ::cFontName )
      // Pre-registered
   elseif ::Container != nil .AND. ValType( ::Container:cFontName ) == "C" .AND. ! Empty( ::Container:cFontName )
      // Container
      ::cFontName := ::Container:cFontName
   elseif ::Parent != nil .AND. ValType( ::Parent:cFontName ) == "C" .AND. ! Empty( ::Parent:cFontName )
      // Parent form
      ::cFontName := ::Parent:cFontName
   else
       // Default
      ::cFontName := _OOHG_DefaultFontName
   endif

   // Font Size:
   If ValType( nFontSize ) == "N" .AND. nFontSize != 0
      // Specified size
      ::nFontSize := nFontSize
   ElseIf ValType( ::nFontSize ) == "N" .AND. ::nFontSize != 0
      // Pre-registered
   elseif ::Container != nil .AND. ValType( ::Container:nFontSize ) == "N" .AND. ::Container:nFontSize != 0
      // Container
      ::nFontSize := ::Container:nFontSize
   elseif ::Parent != nil .AND. ValType( ::Parent:nFontSize ) == "N" .AND. ::Parent:nFontSize != 0
      // Parent form
      ::nFontSize := ::Parent:nFontSize
   else
       // Default
      ::nFontSize := _OOHG_DefaultFontSize
   endif

   // Font Color:
   If ValType( uFontColor ) $ "ANCM"
      // Specified color
      ::FontColor := uFontColor
   ElseIf ValType( ::FontColor ) $ "ANCM"
      // Pre-registered
      * To detect about "-1" !!!
   elseif ::Container != nil .AND. ValType( ::Container:FontColor ) $ "ANCM"
      // Container
      ::FontColor := ::Container:FontColor
   elseif ::Parent != nil .AND. ValType( ::Parent:FontColor ) $ "ANCM"
      // Parent form
      ::FontColor := ::Parent:FontColor
   else
       // Default
   endif

Return Self

*-----------------------------------------------------------------------------*
METHOD Error() CLASS TWindow
*-----------------------------------------------------------------------------*
Local nPos, cMessage
   cMessage := __GetMessage()
   nPos := aScan( ::aControlsNames, UPPER( ALLTRIM( cMessage ) ) + CHR( 255 ) )
Return IF( nPos > 0, ::aControls[ nPos ], ::MsgNotFound( cMessage ) )

*-----------------------------------------------------------------------------*
METHOD Control( cControl ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local nPos
   nPos := aScan( ::aControlsNames, UPPER( ALLTRIM( cControl ) ) + CHR( 255 ) )
Return IF( nPos > 0, ::aControls[ nPos ], nil )

#define HOTKEY_ID        1
#define HOTKEY_MOD       2
#define HOTKEY_KEY       3
#define HOTKEY_ACTION    4

*-----------------------------------------------------------------------------*
METHOD HotKey( nKey, nFlags, bAction ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local nPos, nId, uRet := nil
   nPos := ASCAN( ::aHotKeys, { |a| a[ HOTKEY_KEY ] == nKey .AND. a[ HOTKEY_MOD ] == nFlags } )
   If nPos > 0
      uRet := ::aHotKeys[ nPos ][ HOTKEY_ACTION ]
   EndIf
   If PCOUNT() > 2
      If ValType( bAction ) == "B"
         If nPos > 0
            ::aHotKeys[ nPos ][ HOTKEY_ACTION ] := bAction
         Else
            nId := _GetId()
            AADD( ::aHotKeys, { nId, nFlags, nKey, bAction } )
            InitHotKey( ::hWnd, nFlags, nKey, nId )
         EndIf
      Else
         If nPos > 0
            ReleaseHotKey( ::hWnd, ::aHotKeys[ nPos ][ HOTKEY_ID ] )
            _OOHG_DeleteArrayItem( ::aHotKeys, nPos )
         EndIf
      Endif
   EndIf
Return uRet

*-----------------------------------------------------------------------------*
METHOD SetKey( nKey, nFlags, bAction ) CLASS TWindow
*-----------------------------------------------------------------------------*
Return _OOHG_SetKey( ::aKeys, nKey, nFlags, bAction )

*-----------------------------------------------------------------------------*
METHOD LookForKey( nKey, nFlags ) CLASS TWindow
*-----------------------------------------------------------------------------*
Local lDone
   If ::Active .AND. LookForKey_Check_HotKey( ::aKeys, nKey, nFlags, Self )
      lDone := .T.
   ElseIf ::Active .AND. LookForKey_Check_bKeyDown( ::bKeyDown, nKey, nFlags )
      lDone := .T.
   ElseIf ValType( ::Container ) == "O"
      lDone := ::Container:LookForKey( nKey, nFlags )
   ElseIf ValType( ::Parent ) == "O" .AND. ::lInternal
      lDone := ::Parent:LookForKey( nKey, nFlags )
   Else
      If LookForKey_Check_HotKey( _OOHG_HotKeys, nKey, nFlags, nil )
         lDone := .T.
      ElseIf LookForKey_Check_bKeyDown( _OOHG_bKeyDown, nKey, nFlags )
         lDone := .T.
      Else
         lDone := .F.
      EndIf
   EndIf
Return lDone

STATIC FUNCTION LookForKey_Check_HotKey( aKeys, nKey, nFlags, Self )
Local nPos, lDone
   nPos := ASCAN( aKeys, { |a| a[ HOTKEY_KEY ] == nKey .AND. nFlags == a[ HOTKEY_MOD ] } )
   If nPos > 0
      If Self == NIL
         Eval( aKeys[ nPos ][ HOTKEY_ACTION ], nKey, nFlags )
      Else
         ::DoEvent( { || Eval( aKeys[ nPos ][ HOTKEY_ACTION ], nKey, nFlags ) }, "" )
      EndIf
      lDone := .T.
   Else
      lDone := .F.
   EndIf
Return lDone

STATIC FUNCTION LookForKey_Check_bKeyDown( bKeyDown, nKey, nFlags )
Local lDone
   If ValType( bKeyDown ) == "B"
      lDone := Eval( bKeyDown, nKey, nFlags )
      If ValType( lDone ) != "L"
         lDone := .F.
      EndIf
   Else
      lDone := .F.
   EndIf
Return lDone

*------------------------------------------------------------------------------*
METHOD Visible( lVisible ) CLASS TWindow
*------------------------------------------------------------------------------*
   If ValType( lVisible ) == "L"
      ::lVisible := lVisible
      If lVisible .AND. ::ContainerVisible
         CShowControl( ::hWnd )
      Else
         HideWindow( ::hWnd )
      EndIf
      ProcessMessages()
   EndIf
Return ::lVisible

*------------------------------------------------------------------------------*
FUNCTION _OOHG_AddFrame( oFrame )
*------------------------------------------------------------------------------*
   AADD( _OOHG_ActiveFrame, oFrame )
Return oFrame

*------------------------------------------------------------------------------*
FUNCTION _OOHG_DeleteFrame( cType )
*------------------------------------------------------------------------------*
Local oCtrl
   If LEN( _OOHG_ActiveFrame ) == 0
      // ERROR: No FRAME started
      Return .F.
   EndIf
   oCtrl := ATAIL( _OOHG_ActiveFrame )
   If oCtrl:Type == cType
      ASIZE( _OOHG_ActiveFrame, LEN( _OOHG_ActiveFrame ) - 1 )
   Else
      // ERROR: No FRAME started
      Return .F.
   EndIf
Return .T.

*------------------------------------------------------------------------------*
FUNCTION _OOHG_LastFrame()
*------------------------------------------------------------------------------*
Local cRet
   If LEN( _OOHG_ActiveFrame ) == 0
      cRet := ""
   Else
      cRet := ATAIL( _OOHG_ActiveFrame ):Type
   EndIf
Return cRet

#pragma BEGINDUMP
HB_FUNC( _OOHG_SELECTSUBCLASS ) // _OOHG_SelectSubClass( oClass, oSubClass )
{
   PHB_ITEM pRet, pCopy;

   pCopy = hb_itemNew( NULL );
   pRet = hb_param( 2, HB_IT_OBJECT );
   if( ! pRet )
   {
      pRet = hb_param( 1, HB_IT_ANY );
   }
   hb_itemCopy( pCopy, pRet );
   hb_itemReturn( pCopy );
   hb_itemRelease( pCopy );
// Return if( ValType( oSubClass ) == "O", oSubClass, oClass )
}
#pragma ENDDUMP

*------------------------------------------------------------------------------*
CLASS TForm FROM TWindow
*------------------------------------------------------------------------------*
   DATA ToolTipHandle  INIT 0
   DATA Focused        INIT .F.
   DATA LastFocusedControl INIT 0
   DATA AutoRelease    INIT .F.
   DATA ActivateCount  INIT { 0 }
   DATA oMenu          INIT nil
   DATA hWndClient     INIT 0
   DATA lInternal      INIT .F.
   DATA lForm          INIT .T.
   DATA nWidth         INIT 300
   DATA nHeight        INIT 300
   DATA lShowed        INIT .F.

   DATA OnRelease      INIT nil
   DATA OnInit         INIT nil
   DATA OnSize         INIT nil
   DATA OnPaint        INIT nil
   DATA OnScrollUp     INIT nil
   DATA OnScrollDown   INIT nil
   DATA OnScrollLeft   INIT nil
   DATA OnScrollRight  INIT nil
   DATA OnHScrollBox   INIT nil
   DATA OnVScrollBox   INIT nil
   DATA OnInteractiveClose INIT nil
   DATA OnMaximize     INIT nil
   DATA OnMinimize     INIT nil
   DATA OnRestore      INIT nil

   DATA nVirtualHeight INIT 0
   DATA nVirtualWidth  INIT 0
   DATA RangeHeight    INIT 0
   DATA RangeWidth     INIT 0

   DATA GraphTasks     INIT {}
   DATA GraphCommand   INIT nil
   DATA GraphData      INIT {}
   DATA BrowseList     INIT {}    // Controls to be refresh at form's draw.
   DATA SplitChildList INIT {}    // INTERNAL windows.

   DATA NotifyIconLeftClick   INIT nil
   DATA NotifyMenu            INIT nil
   DATA cNotifyIconName       INIT ""
   DATA cNotifyIconToolTip    INIT ""
   METHOD NotifyIcon          SETGET
   METHOD NotifyToolTip       SETGET
   METHOD Title               SETGET
   METHOD Height              SETGET
   METHOD Width               SETGET
   METHOD Col                 SETGET
   METHOD Row                 SETGET
   METHOD Cursor              SETGET
   METHOD BackColor           SETGET
   METHOD VirtualWidth        SETGET
   METHOD VirtualHeight       SETGET

   METHOD FocusedControl
   METHOD SizePos
   METHOD Define
   METHOD Define2
   METHOD Register
   METHOD Visible       SETGET
   METHOD Activate
   METHOD Release
   METHOD Center()      BLOCK { | Self | C_Center( ::hWnd ) }
   METHOD Restore()     BLOCK { | Self | Restore( ::hWnd ) }
   METHOD Minimize()    BLOCK { | Self | Minimize( ::hWnd ) }
   METHOD Maximize()    BLOCK { | Self | Maximize( ::hWnd ) }

   METHOD SetFocusedSplitChild
   METHOD SetActivationFocus
   METHOD ProcessInitProcedure
   METHOD RefreshData
   METHOD DeleteControl
   METHOD OnHideFocusManagement
   METHOD CheckInteractiveClose()
   METHOD DoEvent

   METHOD Events
   METHOD Events_Destroy
   METHOD Events_VScroll
   METHOD Events_HScroll
   METHOD ScrollControls
   METHOD MessageLoop

ENDCLASS

*------------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, topmost, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, NoAutoRelease, oParent, ;
               InteractiveCloseProcedure, lRtl, child, mdi, clientarea, ;
               restoreprocedure ) CLASS TForm
*------------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0
Local hParent

   If ValType( child ) == "L" .AND. child
      ::Type := "C"
      oParent := ::SearchParent( oParent )
      hParent := oParent:hWnd
   Else
      ::Type := "S"
      hParent := 0
   EndIf

   nStyle   += WS_POPUP

   ::Define2( FormName, Caption, x, y, w, h, hParent, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
              nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
              minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
              0, lRtl, mdi, topmost, clientarea, restoreprocedure )

Return Self

*------------------------------------------------------------------------------*
METHOD Define2( FormName, Caption, x, y, w, h, Parent, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
                nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
                icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
                minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
                MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
                nWindowType, lRtl, mdi, topmost, clientarea, restoreprocedure ) CLASS TForm
*------------------------------------------------------------------------------*
Local Formhandle, aClientRect

   If _OOHG_GlobalRTL()
      lRtl := .T.
   ElseIf ValType( lRtl ) != "L"
      lRtl := .F.
   Endif

   ::lRtl := lRtl

   if ! valtype( FormName ) $ "CM"
      FormName := _OOHG_TempWindowName
	endif

   FormName := _OOHG_GetNullName( FormName )

   If _IsWindowDefined( FormName )
      MsgOOHGError( "Window: " + FormName + " already defined. Program Terminated" )
	endif

   if ! valtype( Caption ) $ "CM"
		Caption := ""
	endif

   ASSIGN ::nVirtualHeight VALUE VirtualHeight TYPE "N"
   ASSIGN ::nVirtualWidth  VALUE VirtualWidth  TYPE "N"

   if ! Valtype( aRGB ) $ 'AN'
      aRGB := GetSysColor( COLOR_3DFACE )
	EndIf

   If ValType( helpbutton ) == "L" .AND. helpbutton
      nStyleEx += WS_EX_CONTEXTHELP
   Else
      nStyle += if( ValType( nominimize ) != "L" .OR. ! nominimize, WS_MINIMIZEBOX, 0 ) + ;
                if( ValType( nomaximize ) != "L" .OR. ! nomaximize, WS_MAXIMIZEBOX, 0 )
   EndIf
   nStyle    += if( ValType( nosize )     != "L" .OR. ! nosize,    WS_SIZEBOX, 0 ) + ;
                if( ValType( nosysmenu )  != "L" .OR. ! nosysmenu, WS_SYSMENU, 0 ) + ;
                if( ValType( nocaption )  != "L" .OR. ! nocaption, WS_CAPTION, 0 )

   nStyleEx += if( ValType( topmost ) == "L" .AND. topmost, WS_EX_TOPMOST, 0 )

   If ValType( mdi ) == "L" .AND. mdi
      If nWindowType != 0
         *  mdichild .OR. mdiclient // .OR. splitchild
         * These windows' types can't be MDI FRAME
      EndIf
      nWindowType := 4
      nStyle   += WS_CLIPSIBLINGS + WS_CLIPCHILDREN // + WS_THICKFRAME
* propiedad si es MDI????
   Else
      mdi := .F.
   EndIf

   ASSIGN ::nRow    VALUE y TYPE "N"
   ASSIGN ::nCol    VALUE x TYPE "N"
   ASSIGN ::nWidth  VALUE w TYPE "N"
   ASSIGN ::nHeight VALUE h TYPE "N"

   If ::lInternal
      x := ::ContainerCol
      y := ::ContainerRow
   Else
      x := ::nCol
      y := ::nRow
   EndIf
   If nWindowType == 2
      Formhandle := InitWindowMDIClient( Caption, x, y, ::nWidth, ::nHeight, Parent, "MDICLIENT", nStyle, nStyleEx, lRtl )
   Else
      UnRegisterWindow( FormName )
      ::BrushHandle := RegisterWindow( icon, FormName, aRGB, nWindowType )
      Formhandle := InitWindow( Caption, x, y, ::nWidth, ::nHeight, Parent, FormName, nStyle, nStyleEx, lRtl )
   EndIf

   if Valtype( cursor ) $ "CM"
		SetWindowCursor( Formhandle , cursor )
	EndIf

   ::Register( FormHandle, FormName )
   ::ToolTipHandle := InitToolTip( FormHandle, _SetToolTipBalloon(), _SetTooltipBackcolor(), _SetTooltipForecolor() )

   ASSIGN clientarea VALUE clientarea TYPE "L" DEFAULT .F.
   If clientarea
      aClientRect := { 0, 0, 0, 0 }
      GetClientRect( ::hWnd, aClientRect )
      ::Width  := ::Width  + ::Width  - aClientRect[ 3 ] - aClientRect[ 1 ]
      ::Height := ::Height + ::Height - aClientRect[ 4 ] - aClientRect[ 2 ]
   EndIf

   ::ParentDefaults( FontName, FontSize )

   AADD( _OOHG_ActiveForm, Self )

   InitDummy( FormHandle )

   ::HScrollbar := TScrollBar():Define( "0", Self,,,,,,,, ;
                   { |Scroll| _OOHG_Eval( ::OnScrollLeft, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnScrollRight, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnHScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnHScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnHScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnHScrollBox, Scroll ) }, ;
                   { |Scroll,n| _OOHG_Eval( ::OnHScrollBox, Scroll, n ) }, ;
                   ,,,,,, SB_HORZ, .T. )
   ::HScrollBar:nLineSkip  := 1
   ::HScrollBar:nPageSkip  := 20

   ::VScrollbar := TScrollBar():Define( "0", Self,,,,,,,, ;
                   { |Scroll| _OOHG_Eval( ::OnScrollUp, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnScrollDown, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnVScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnVScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnVScrollBox, Scroll ) }, ;
                   { |Scroll| _OOHG_Eval( ::OnVScrollBox, Scroll ) }, ;
                   { |Scroll,n| _OOHG_Eval( ::OnVScrollBox, Scroll, n ) }, ;
                   ,,,,,, SB_VERT, .T. )
   ::VScrollBar:nLineSkip  := 1
   ::VScrollBar:nPageSkip  := 20

   ValidateScrolls( Self, .F. )

   ::OnRelease := ReleaseProcedure
   ::OnInit := InitProcedure
   ::OnSize := SizeProcedure
   ::OnClick := ClickProcedure
   ::OnGotFocus := GotFocus
   ::OnLostFocus := LostFocus
   ::OnPaint := PaintProcedure
   ::OnMouseDrag := MouseDragProcedure
   ::OnMouseMove := MouseMoveProcedure
   ::OnScrollUp := ScrollUp
   ::OnScrollDown := ScrollDown
   ::OnScrollLeft := ScrollLeft
   ::OnScrollRight := ScrollRight
   ::OnHScrollBox := HScrollBox
   ::OnVScrollBox := VScrollBox
   ::OnInteractiveClose := InteractiveCloseProcedure
   ::OnMaximize := MaximizeProcedure
   ::OnMinimize := MinimizeProcedure
   ::OnRestore  := RestoreProcedure
   ::lVisible := ! ( ValType( NoShow ) == "L" .AND. NoShow )
   ::BackColor := aRGB
   ::AutoRelease := ! ( ValType( NoAutoRelease ) == "L" .AND. NoAutoRelease )

   _OOHG_ThisForm := Self

Return Self


*--------------------------------------------------
Function _SetToolTipBalloon ( lNewBalloon )
*--------------------------------------------------
Static lBalloon := .F.
Local oreg,lOldBalloon := lBalloon
Local lSiono



        If lNewBalloon <> Nil
        if lNewBalloon
           oreg:=TReg32():New(HKEY_CURRENT_USER,"Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced",.F.)
           oreg:get("EnableBalloonTips",lsiono)
           oreg:close()
        endif
            lBalloon := lNewBalloon
        Endif

return lOldBalloon

*------------------------------------------------------------------------------*
METHOD Register( hWnd, cName ) CLASS TForm
*------------------------------------------------------------------------------*
Local mVar
   ::hWnd := hWnd
   ::StartInfo( hWnd )
   ::Name := cName

   AADD( _OOHG_aFormhWnd,    hWnd )
   AADD( _OOHG_aFormObjects, Self )

   mVar := "_" + cName
   Public &mVar. := Self
RETURN Self

*-----------------------------------------------------------------------------*
METHOD Visible( lVisible ) CLASS TForm
*-----------------------------------------------------------------------------*
   IF VALTYPE( lVisible ) == "L"
      ::Super:Visible := lVisible
      IF ! lVisible
         ::OnHideFocusManagement()
      ELSEIF ! ::lShowed
         If ! ::SetFocusedSplitChild()
            ::SetActivationFocus()
         EndIf
         ::lShowed := .T.
      ENDIF
   ENDIF
Return ::lVisible

*-----------------------------------------------------------------------------*
METHOD Activate( lNoStop, oWndLoop ) CLASS TForm
*-----------------------------------------------------------------------------*

   ASSIGN lNoStop VALUE lNoStop TYPE "L" DEFAULT .F.

   If _OOHG_ThisEventType == 'WINDOW_RELEASE' .AND. ! lNoStop
      MsgOOHGError("ACTIVATE WINDOW: activate windows within an 'on release' window procedure is not allowed. Program terminated" )
	EndIf

   If Len( _OOHG_ActiveForm ) > 0
      MsgOOHGError("ACTIVATE WINDOW: DEFINE WINDOW Structure is not closed. Program terminated" )
	Endif

   If _OOHG_ThisEventType == 'WINDOW_GOTFOCUS'
      MsgOOHGError("ACTIVATE WINDOW / Activate(): Not allowed in window's GOTFOCUS event procedure. Program terminated" )
	Endif

   If _OOHG_ThisEventType == 'WINDOW_LOSTFOCUS'
      MsgOOHGError("ACTIVATE WINDOW / Activate(): Not allowed in window's LOSTFOCUS event procedure. Program terminated" )
	Endif

	// Main Check

   // Not mandatory MAIN
   // If _OOHG_Main == nil
   //    MsgOOHGError( "ACTIVATE WINDOW: Main Window not defined. Program terminated." )
   // ElseIf ! _OOHG_Main:lFirstActivate
   //    MsgOOHGError( "ACTIVATE WINDOW: Main Window Must be Activated In First ACTIVATE WINDOW Command. Program terminated." )
   // EndIf

   If ::Active
      MsgOOHGError( "Window: " + ::Name + " already active. Program terminated" )
   Endif

   // Checks for non-stop window
   If ValType( oWndLoop ) != "O"
      oWndLoop := IF( lNoStop .AND. ValType( _OOHG_Main ) == "O", _OOHG_Main, Self )
   EndIf
   ::ActivateCount := oWndLoop:ActivateCount
   ::ActivateCount[ 1 ]++

   // Show window

* Testing... it allows to create non-modal windows when modal windows are active.
* The problem is, what should do when modal window is ... disabled? hidden? WM_CLOSE? WM_DESTROY?
/*
      If Len( _OOHG_ActiveModal ) != 0 .AND. ATAIL( _OOHG_ActiveModal ):Active
         MsgOOHGError("Non Modal Windows can't be activated when a modal window is active. " + ::Name + ". Program Terminated" )
      endif
*/

   If ::lVisible
      _OOHG_UserWindow := Self
      ::Show()
      // If ! ::SetFocusedSplitChild()
      //    ::SetActivationFocus()
      // EndIf
   EndIf

   ::Active := .T.
   ::ProcessInitProcedure()
   ::RefreshData()

   // Starts the Message Loop
   If ! lNoStop
      ::MessageLoop()
   EndIf

Return Nil

*-----------------------------------------------------------------------------*
METHOD MessageLoop() CLASS TForm
*-----------------------------------------------------------------------------*
   AADD( _OOHG_MessageLoops, ::ActivateCount )
   _DoMessageLoop()
   _OOHG_DeleteArrayItem( _OOHG_MessageLoops, Len( _OOHG_MessageLoops ) )
   If Len( _OOHG_MessageLoops ) > 0 .AND. ATAIL( _OOHG_MessageLoops )[ 1 ] < 1
      PostQuitMessage( 0 )
   EndIf
Return nil

*-----------------------------------------------------------------------------*
METHOD Release() CLASS TForm
*-----------------------------------------------------------------------------*
   If ! ::lReleasing
      ::lReleasing := .T.

      If ! ::Active
         MsgOOHGError( "Window: " + ::Name + " is not active. Program terminated." )
      Endif

      * Release Window

      If ValidHandler( ::hWnd )
         EnableWindow( ::hWnd )
         SendMessage( ::hWnd, WM_SYSCOMMAND, SC_CLOSE, 0 )
      EndIf

      ::Events_Destroy()

//   Else
//      MsgOOHGError( "Release a window in its own 'on release' procedure or release the main window in any 'on release' procedure is not allowed. Program terminated." )
   Endif
Return Nil

*-----------------------------------------------------------------------------*
METHOD SetFocusedSplitChild() CLASS TForm
*-----------------------------------------------------------------------------*
Local SplitFocusFlag := .F.
   AEVAL( ::SplitChildList, { |o| if( o:Focused, ( o:SetFocus() , SplitFocusFlag := .T. ), ) } )
Return SplitFocusFlag

*-----------------------------------------------------------------------------*
METHOD SetActivationFocus() CLASS TForm
*-----------------------------------------------------------------------------*
Local Sp
   Sp := GetFocus()

   IF ASCAN( ::aControls, { |o| o:hWnd == Sp } ) == 0
      setfocus( GetNextDlgTabItem( ::hWnd , 0 , 0 ) )
   ENDIF
Return nil

*-----------------------------------------------------------------------------*
METHOD ProcessInitProcedure() CLASS TForm
*-----------------------------------------------------------------------------*
   if valtype( ::OnInit )=='B'
      ProcessMessages()
      AADD( _OOHG_MessageLoops, ::ActivateCount )
      ::DoEvent( ::OnInit, "WINDOW_INIT" )
      _OOHG_DeleteArrayItem( _OOHG_MessageLoops, Len( _OOHG_MessageLoops ) )
   EndIf
   AEVAL( ::SplitChildList, { |o| o:ProcessInitProcedure() } )
Return nil

*-----------------------------------------------------------------------------*
METHOD NotifyIcon( IconName ) CLASS TForm
*-----------------------------------------------------------------------------*
   IF PCOUNT() > 0
      ChangeNotifyIcon( ::hWnd, LoadTrayIcon(GETINSTANCE(), IconName ) , ::NotifyTooltip )
      ::cNotifyIconName := IconName
   ENDIF
RETURN ::cNotifyIconName

*-----------------------------------------------------------------------------*
METHOD NotifyTooltip( TooltipText ) CLASS TForm
*-----------------------------------------------------------------------------*
   IF PCOUNT() > 0
      ChangeNotifyIcon( ::hWnd, LoadTrayIcon(GETINSTANCE(), ::NotifyIcon ) , TooltipText )
      ::cNotifyIconTooltip := TooltipText
   ENDIF
RETURN ::cNotifyIconTooltip

*------------------------------------------------------------------------------*
METHOD Title( cTitle ) CLASS TForm
*------------------------------------------------------------------------------*
Return ( ::Caption := cTitle )

*------------------------------------------------------------------------------*
METHOD Height( nHeight ) CLASS TForm
*------------------------------------------------------------------------------*
   if valtype( nHeight ) == "N"
      ::SizePos( , , , nHeight )
   endif
Return GetWindowHeight( ::hWnd )

*------------------------------------------------------------------------------*
METHOD Width( nWidth ) CLASS TForm
*------------------------------------------------------------------------------*
   if valtype( nWidth ) == "N"
      ::SizePos( , , nWidth )
   endif
Return GetWindowWidth( ::hWnd )

*------------------------------------------------------------------------------*
METHOD Col( nCol ) CLASS TForm
*------------------------------------------------------------------------------*
   if valtype( nCol ) == "N"
      ::SizePos( , nCol )
   endif
Return GetWindowCol( ::hWnd )

*------------------------------------------------------------------------------*
METHOD Row( nRow ) CLASS TForm
*------------------------------------------------------------------------------*
   If valtype( nRow ) == "N"
      ::SizePos( nRow )
   EndIf
Return GetWindowRow( ::hWnd )

*------------------------------------------------------------------------------*
METHOD VirtualWidth( nSize ) CLASS TForm
*------------------------------------------------------------------------------*
   If valtype( nSize ) == "N"
      ::nVirtualWidth := nSize
      ValidateScrolls( Self, .T. )
   EndIf
Return ::nVirtualWidth

*------------------------------------------------------------------------------*
METHOD VirtualHeight( nSize ) CLASS TForm
*------------------------------------------------------------------------------*
   If valtype( nSize ) == "N"
      ::nVirtualHeight := nSize
      ValidateScrolls( Self, .T. )
   EndIf
Return ::nVirtualHeight

*------------------------------------------------------------------------------*
METHOD FocusedControl() CLASS TForm
*------------------------------------------------------------------------------*
Local hWnd, nPos
   hWnd := GetFocus()
   nPos := 0
   DO WHILE nPos == 0
      nPos := ASCAN( ::aControls, { |o| o:hWnd == hWnd } )
      IF nPos == 0
         hWnd := GetParent( hWnd )
         IF hWnd == ::hWnd .OR. ! ValidHandler( hWnd )
            EXIT
         ENDIF
      ENDIF
   ENDDO
Return if( nPos == 0, "", ::aControls[ nPos ]:Name )

*------------------------------------------------------------------------------*
METHOD Cursor( uValue ) CLASS TForm
*------------------------------------------------------------------------------*
   IF uValue != nil
      SetWindowCursor( ::hWnd, uValue )
   ENDIF
Return nil

#pragma BEGINDUMP
HB_FUNC_STATIC( TFORM_BACKCOLOR )
{
   PHB_ITEM pSelf = hb_stackSelfItem();
   POCTRL oSelf = _OOHG_GetControlInfo( pSelf );

   if( _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &oSelf->lBackColor, ( hb_pcount() >= 1 ) ) )
   {
      if( oSelf->BrushHandle )
      {
         DeleteObject( oSelf->BrushHandle );
         oSelf->BrushHandle = 0;
      }
      if( ValidHandler( oSelf->hWnd ) )
      {
         if( oSelf->lBackColor != -1 )
         {
            oSelf->BrushHandle = CreateSolidBrush( oSelf->lBackColor );
            SetClassLong( oSelf->hWnd, GCL_HBRBACKGROUND, ( long ) oSelf->BrushHandle );
         }
         else
         {
            SetClassLong( oSelf->hWnd, GCL_HBRBACKGROUND, ( long )( COLOR_BTNFACE + 1 ) );
         }
         RedrawWindow( oSelf->hWnd, NULL, NULL, RDW_ERASE | RDW_INVALIDATE | RDW_ALLCHILDREN | RDW_ERASENOW | RDW_UPDATENOW );
      }
   }

   // Return value was set in _OOHG_DetermineColorReturn()
}
#pragma ENDDUMP

*------------------------------------------------------------------------------*
METHOD SizePos( nRow, nCol, nWidth, nHeight ) CLASS TForm
*------------------------------------------------------------------------------*
local actpos:={0,0,0,0}
   GetWindowRect( ::hWnd, actpos )
   if valtype( nCol ) != "N"
      nCol := actpos[ 1 ]
   endif
   if valtype( nRow ) != "N"
      nRow := actpos[ 2 ]
   endif
   if valtype( nWidth ) != "N"
      nWidth := actpos[ 3 ] - actpos[ 1 ]
   endif
   if valtype( nHeight ) != "N"
      nHeight := actpos[ 4 ] - actpos[ 2 ]
   endif
Return MoveWindow( ::hWnd , nCol , nRow , nWidth , nHeight , .t. )

*-----------------------------------------------------------------------------*
METHOD DeleteControl( oControl ) CLASS TForm
*-----------------------------------------------------------------------------*
Local nPos
   // Removes from ::BrowseList
   nPos := aScan( ::BrowseList, { |o| o:hWnd == oControl:hWnd } )
   If nPos > 0
      _OOHG_DeleteArrayItem( ::BrowseList, nPos )
   EndIf
   // Removes INTERNAL window from ::SplitChildList
   // If oControl:lForm .....
   nPos := aScan( ::SplitChildList, { |o| o:hWnd == oControl:hWnd } )
   If nPos > 0
      _OOHG_DeleteArrayItem( ::SplitChildList, nPos )
   EndIf
Return ::Super:DeleteControl( oControl )

*-----------------------------------------------------------------------------*
METHOD RefreshData() CLASS TForm
*-----------------------------------------------------------------------------*
   AEVAL( ::BrowseList, { |o| o:RefreshData() } )
Return nil

*-----------------------------------------------------------------------------*
METHOD OnHideFocusManagement() CLASS TForm
*-----------------------------------------------------------------------------*
Return nil

*-----------------------------------------------------------------------------*
METHOD CheckInteractiveClose() CLASS TForm
*-----------------------------------------------------------------------------*
Local lRet := .T.
   Do Case
      Case _OOHG_InteractiveClose == 0
         MsgStop( _OOHG_Messages( 1, 3 ) )
         lRet := .F.
      Case _OOHG_InteractiveClose == 2
         lRet := MsgYesNo( _OOHG_Messages( 1, 1 ), _OOHG_Messages( 1, 2 ) )
   EndCase
Return lRet

*-----------------------------------------------------------------------------*
METHOD DoEvent( bBlock, cEventType ) CLASS TForm
*-----------------------------------------------------------------------------*
Local lRetVal := .F.
   If valtype( bBlock ) == "B"
		_PushEventInfo()
      _OOHG_ThisForm      := Self
      _OOHG_ThisEventType := cEventType
      _OOHG_ThisType      := "W"
      _OOHG_ThisControl   := NIL
      _OOHG_ThisObject    := Self
		lRetVal := Eval( bBlock )
		_PopEventInfo()
	EndIf
Return lRetVal

*-----------------------------------------------------------------------------*
METHOD Events_Destroy() CLASS TForm
*-----------------------------------------------------------------------------*
Local mVar, i

   // Release hot keys
   aEval( ::aHotKeys, { |a| ReleaseHotKey( ::hWnd, a[ HOTKEY_ID ] ) } )
   ::aHotKeys := {}

   // Remove Child Controls
   DO WHILE LEN( ::aControls ) > 0
      ::aControls[ 1 ]:Release()
   ENDDO

   IF ::Active
      // Delete Notify icon
      ShowNotifyIcon( ::hWnd, .F. , 0, "" )
      If ::NotifyMenu != nil
         ::NotifyMenu:Release()
      EndIf

      If ::oMenu != NIL
         ::oMenu:Release()
         ::oMenu := nil
      EndIf

      // Update Form Index Variable
      If ! Empty( ::Name )
         mVar := '_' + ::Name
         if type( mVar ) != 'U'
            __MVPUT( mVar , 0 )
         EndIf
      EndIf

      // Removes from container
      If ::Container != NIL
         ::Container:DeleteControl( Self )
      EndIf

      // Removes from parent
      If ::Parent != NIL
         ::Parent:DeleteControl( Self )
      EndIf

      // Verify if window was multi-activated
      ::ActivateCount[ 1 ]--
      If Len( _OOHG_MessageLoops ) > 0
         If ATAIL( _OOHG_MessageLoops )[ 1 ] < 1
            PostQuitMessage( 0 )
         Endif
      ElseIf ::ActivateCount[ 1 ] < 1
         PostQuitMessage( 0 )
      Endif

      // Removes WINDOW from the array
      i := Ascan( _OOHG_aFormhWnd, ::hWnd )
      IF i > 0
         _OOHG_DeleteArrayItem( _OOHG_aFormhWnd, I )
         _OOHG_DeleteArrayItem( _OOHG_aFormObjects, I )
      ENDIF

      *** ::Type == "MODAL"
      // Eliminates active modal
      IF Len( _OOHG_ActiveModal ) != 0 .AND. ATAIL( _OOHG_ActiveModal ):hWnd == ::hWnd
         _OOHG_DeleteArrayItem( _OOHG_ActiveModal, Len( _OOHG_ActiveModal ) )
      ENDIF

      ::Active := .F.
      ::Super:Release()

   EndIf

Return nil

*-----------------------------------------------------------------------------*
METHOD Events_VScroll( wParam ) CLASS TForm
*-----------------------------------------------------------------------------*
Local uRet
   uRet := ::VScrollBar:Events_VScroll( wParam )
   ::RowMargin := - ::VScrollBar:Value
   ::ScrollControls()
Return uRet

*-----------------------------------------------------------------------------*
METHOD Events_HScroll( wParam ) CLASS TForm
*-----------------------------------------------------------------------------*
Local uRet
   uRet := ::HScrollBar:Events_HScroll( wParam )
   ::ColMargin := - ::HScrollBar:Value
   ::ScrollControls()
Return uRet

*-----------------------------------------------------------------------------*
METHOD ScrollControls() CLASS TForm
*-----------------------------------------------------------------------------*
   AEVAL( ::aControls, { |o| If( o:Container == nil, o:SizePos(), ) } )
   ReDrawWindow( ::hWnd )
RETURN Self

#pragma BEGINDUMP

// -----------------------------------------------------------------------------
HB_FUNC_STATIC( TFORM_EVENTS )   // METHOD Events( hWnd, nMsg, wParam, lParam ) CLASS TForm
// -----------------------------------------------------------------------------
{
   static PHB_SYMB s_Events2 = 0;

   HWND hWnd      = HWNDparam( 1 );
   UINT message   = ( UINT )   hb_parni( 2 );
   WPARAM wParam  = ( WPARAM ) hb_parni( 3 );
   LPARAM lParam  = ( LPARAM ) hb_parnl( 4 );
   PHB_ITEM pSelf = hb_stackSelfItem();

   switch( message )
   {
      case WM_LBUTTONUP:
         _OOHG_SetMouseCoords( pSelf, LOWORD( lParam ), HIWORD( lParam ) );
         _OOHG_Send( pSelf, s_OnClick );
         hb_vmSend( 0 );
         _OOHG_Send( pSelf, s_DoEvent );
         hb_vmPush( hb_param( -1, HB_IT_ANY ) );
         hb_vmPushString( "", 0 );
         hb_vmSend( 2 );
         hb_ret();
         break;

      case WM_LBUTTONDOWN:
         _OOHG_SetMouseCoords( pSelf, LOWORD( lParam ), HIWORD( lParam ) );
         hb_ret();
         break;

      case WM_MOUSEMOVE:
         _OOHG_SetMouseCoords( pSelf, LOWORD( lParam ), HIWORD( lParam ) );
         if( wParam == MK_LBUTTON )
         {
            _OOHG_Send( pSelf, s_OnMouseDrag );
         }
         else
         {
            _OOHG_Send( pSelf, s_OnMouseMove );
         }
         hb_vmSend( 0 );
         _OOHG_Send( pSelf, s_DoEvent );
         hb_vmPush( hb_param( -1, HB_IT_ANY ) );
         hb_vmPushString( "", 0 );
         hb_vmSend( 2 );
         hb_ret();
         break;

      case WM_MOUSEWHEEL:
         _OOHG_Send( pSelf, s_hWnd );
         hb_vmSend( 0 );
         if( ValidHandler( HWNDparam( -1 ) ) )
         {
            _OOHG_Send( pSelf, s_RangeHeight );
            hb_vmSend( 0 );
            if( hb_parnl( -1 ) > 0 )
            {
               if( ( short ) HIWORD( wParam ) > 0 )
               {
                  _OOHG_Send( pSelf, s_Events_VScroll );
                  hb_vmPushLong( SB_LINEUP );
                  hb_vmSend( 1 );
               }
               else
               {
                  _OOHG_Send( pSelf, s_Events_VScroll );
                  hb_vmPushLong( SB_LINEDOWN );
                  hb_vmSend( 1 );
               }
            }
         }
         hb_ret();
         break;

      default:
         if( ! s_Events2 )
         {
            s_Events2 = hb_dynsymSymbol( hb_dynsymFind( "_OOHG_TFORM_EVENTS2" ) );
         }
         hb_vmPushSymbol( s_Events2 );
         hb_vmPushNil();
         hb_vmPush( pSelf );
         HWNDpush( hWnd );
         hb_vmPushLong( message );
         hb_vmPushLong( wParam );
         hb_vmPushLong( lParam );
         hb_vmDo( 5 );
         break;
   }
}

#pragma ENDDUMP

*-----------------------------------------------------------------------------*
FUNCTION _OOHG_TForm_Events2( Self, hWnd, nMsg, wParam, lParam ) // CLASS TForm
*-----------------------------------------------------------------------------*
Local i, NextControlHandle, xRetVal
Local oCtrl
* Local hWnd := ::hWnd

	do case

        ***********************************************************************
	case nMsg == WM_HOTKEY
        ***********************************************************************

		* Process HotKeys

      i := ASCAN( ::aHotKeys, { |a| a[ HOTKEY_ID ] == wParam } )

      If i > 0

         _OOHG_EVAL( ::aHotKeys[ i ][ HOTKEY_ACTION ] )

      EndIf

        ***********************************************************************
	case nMsg == WM_ACTIVATE
        ***********************************************************************

		if LoWord(wparam) == 0

         aeval( ::aHotKeys, { |a| ReleaseHotKey( ::hWnd, a[ HOTKEY_ID ] ) } )

         ::LastFocusedControl := GetFocus()

         If ! ::ContainerReleasing
            ::DoEvent( ::OnLostFocus, 'WINDOW_LOSTFOCUS' )
         EndIf

		Else

         if Ascan( _OOHG_aFormhWnd, hWnd ) > 0
            UpdateWindow( hWnd )
			EndIf

		EndIf

        ***********************************************************************
	case nMsg == WM_SETFOCUS
        ***********************************************************************

         If ::Active .AND. ! ::lInternal
            _OOHG_UserWindow := Self
			EndIf

         aeval( ::aHotKeys, { |a| ReleaseHotKey( ::hWnd, a[ HOTKEY_ID ] ) } )

         aeval( ::aHotKeys, { |a| InitHotKey( ::hWnd, a[ HOTKEY_MOD ], a[ HOTKEY_KEY ], a[ HOTKEY_ID ] ) } )

         ::DoEvent( ::OnGotFocus, 'WINDOW_GOTFOCUS' )

         if ! empty( ::LastFocusedControl )
            SetFocus( ::LastFocusedControl )
         endif

        ***********************************************************************
	case nMsg == WM_HELP
        ***********************************************************************

      HelpTopic( GetControlObjectByHandle( GetHelpData( lParam ) ):HelpId , 2 )

        ***********************************************************************
	case nMsg == WM_TASKBAR
        ***********************************************************************

		If wParam == ID_TASKBAR .and. lParam # WM_MOUSEMOVE

			do case
				case lParam == WM_LBUTTONDOWN
                  ::DoEvent( ::NotifyIconLeftClick, '' )

				case lParam == WM_RBUTTONDOWN
               If _OOHG_ShowContextMenus()
                  If ::NotifyMenu != nil
                     ::NotifyMenu:Activate()
                  Endif
					EndIf

			endcase
		EndIf

        ***********************************************************************
	case nMsg == WM_NEXTDLGCTL
        ***********************************************************************

         If LoWord( lParam ) != 0
            // wParam contains next control's handler
            NextControlHandle := wParam
         Else
            // wParam indicates next control's direction
            NextControlHandle := GetNextDlgTabItem( hWnd, GetFocus(), wParam )
         EndIf

         oCtrl := GetControlObjectByHandle( NextControlHandle )

         if oCtrl:hWnd == NextControlHandle
            oCtrl:SetFocus()
         else
				setfocus( NextControlHandle )
         endif

         * To update the default pushbutton border!
         * To set the default control identifier!
         * Return 0

        ***********************************************************************
	case nMsg == WM_PAINT
        ***********************************************************************

         AEVAL( ::SplitChildList, { |o| AEVAL( o:GraphTasks, { |b| _OOHG_EVAL( b ) } ), _OOHG_EVAL( o:GraphCommand, o:hWnd, o:GraphData ) } )

         AEVAL( ::GraphTasks, { |b| _OOHG_EVAL( b ) } )
         _OOHG_EVAL( ::GraphCommand, ::hWnd, ::GraphData )

         // This must change for MDI, MDICLIENT or MDICHILD window!
         DefWindowProc( hWnd, nMsg, wParam, lParam )

         ::DoEvent( ::OnPaint, '' )

         return 1

        ***********************************************************************
	case nMsg == WM_SIZE
        ***********************************************************************
      ValidateScrolls( Self, .T. )

      If ::Active
         If wParam == SIZE_MAXIMIZED
            ::DoEvent( ::OnMaximize, '' )
         ElseIf wParam == SIZE_MINIMIZED
            ::DoEvent( ::OnMinimize, '' )
         ElseIf wParam == SIZE_RESTORED
            ::DoEvent( ::OnRestore, '' )
         EndIf
      EndIf

      ::DoEvent( ::OnSize, '' )

      // AEVAL( ::aControls, { |o| o:Events_Size() } )
      AEVAL( ::aControls, { |o| If( o:Container == nil, o:Events_Size(), ) } )

        ***********************************************************************
	case nMsg == WM_CLOSE
        ***********************************************************************

      NOTE : Since ::lReleasing could be changed on each process, it must be validated any time

      // Process Interactive Close Event / Setting
      If ! ::lReleasing .AND. ValType( ::OnInteractiveClose ) == 'B'
         xRetVal := ::DoEvent( ::OnInteractiveClose, 'WINDOW_ONINTERACTIVECLOSE' )
         If ValType( xRetVal ) == 'L' .AND. ! xRetVal
            Return 1
         EndIf
      EndIf

      If ! ::lReleasing .AND. ! ::CheckInteractiveClose()
         Return 1
      EndIf

      // Process AutoRelease Property
      if ! ::lReleasing .AND. ! ::AutoRelease
         ::Hide()
         Return 1
      EndIf

      // If Not AutoRelease Destroy Window

      ::lReleasing := .T.
      ::DoEvent( ::OnRelease, 'WINDOW_RELEASE' )

      if ::Type == "A"
         ReleaseAllWindows()
      Else
/*
Testing...
         If ::Type == "M" .AND. ::ActivateCount[ 1 ] > 1 .OR. ! ::ActivateCount == ATAIL( _OOHG_MessageLoops )
            MsgOOHGError( "Modal windows MUST not be closed while it have sub-windows. Program terminated." )
         EndIf
*/
         ::OnHideFocusManagement()
      EndIf

        ***********************************************************************
	case nMsg == WM_DESTROY
        ***********************************************************************

      ::Events_Destroy()

        ***********************************************************************
   otherwise
        ***********************************************************************

      return ::Super:Events( hWnd, nMsg, wParam, lParam )

	endcase

return nil

*-----------------------------------------------------------------------------*
Procedure ValidateScrolls( Self, lMove )
*-----------------------------------------------------------------------------*
Local hWnd, nVirtualWidth, nVirtualHeight
Local aRect, w, h, hscroll, vscroll

   If ! ValidHandler( ::hWnd ) .OR. ::HScrollBar == nil .OR. ::VScrollBar == nil
      Return
   EndIf

   // Initializes variables
   hWnd := ::hWnd
   nVirtualWidth := ::VirtualWidth
   nVirtualHeight := ::VirtualHeight
   If ValType( lMove ) != "L"
      lMove := .F.
   EndIf
   vscroll := hscroll := .F.
   aRect := ARRAY( 4 )
   GetClientRect( hWnd, aRect )
   w := aRect[ 3 ] - aRect[ 1 ] + IF( IsWindowStyle( ::hWnd, WS_VSCROLL ), GetVScrollBarWidth(),  0 )
   h := aRect[ 4 ] - aRect[ 2 ] + IF( IsWindowStyle( ::hWnd, WS_HSCROLL ), GetHScrollBarHeight(), 0 )
   ::RangeWidth := ::RangeHeight := 0

   // Checks if there's space on the window
   If h < nVirtualHeight
      ::RangeHeight := nVirtualHeight - h
      vscroll := .T.
      w -= GetVScrollBarWidth()
   EndIf
   If w < nVirtualWidth
      ::RangeWidth := nVirtualWidth - w
      hscroll := .T.
      h -= GetHScrollBarHeight()
   EndIf
   If h < nVirtualHeight .AND. ! vscroll
      ::RangeHeight := nVirtualHeight - h
      vscroll := .T.
      w -= GetVScrollBarWidth()
   EndIf

   // Shows/hides scroll bars
   _SetScroll( hWnd, hscroll, vscroll )
   ::VScrollBar:lAutoMove := vscroll
   ::VScrollBar:nPageSkip := h
   ::HScrollBar:lAutoMove := hscroll
   ::HScrollBar:nPageSkip := w

   // Verifies there's no "extra" space derived from resize
   If vscroll
      ::VScrollBar:SetRange( 0, ::VirtualHeight )
      ::VScrollBar:Page := h
      If ::RangeHeight < ( - ::RowMargin )
         ::RowMargin := - ::RangeHeight
         ::VScrollBar:Value := ::RangeHeight
      Else
         vscroll := .F.
      EndIf
   ElseIf nVirtualHeight > 0 .AND. ::RowMargin != 0
      ::RowMargin := 0
      vscroll := .T.
   EndIf
   If hscroll
      ::HScrollBar:SetRange( 0, ::VirtualWidth )
      ::HScrollBar:Page := w
      If ::RangeWidth < ( - ::ColMargin )
         ::ColMargin := - ::RangeWidth
         ::HScrollBar:Value := ::RangeWidth
      Else
         hscroll := .F.
      EndIf
   ElseIf nVirtualWidth > 0 .AND. ::ColMargin != 0
      ::ColMargin := 0
      hscroll := .T.
   EndIf

   // Reubicates controls
   If lMove .AND. ( vscroll .OR. hscroll )
      ::ScrollControls()
   EndIf
Return





*-----------------------------------------------------------------------------*
CLASS TFormMain FROM TForm
*-----------------------------------------------------------------------------*
   DATA Type           INIT "A" READONLY
   DATA lFirstActivate INIT .F.

   METHOD Define
   METHOD Activate
   METHOD Release

   METHOD CheckInteractiveClose
ENDCLASS

*-----------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, topmost, ;
               icon, fontname, fontsize, NotifyIconName, NotifyIconTooltip, ;
               NotifyIconLeftClick, GotFocus, LostFocus, virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, InteractiveCloseProcedure, lRtl, ;
               mdi, clientarea, restoreprocedure ) CLASS TFormMain
*-----------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0

   If _OOHG_Main != nil
      MsgOOHGError( "Main Window Already Defined. Program Terminated." )
   Endif

   _OOHG_Main := Self
   nStyle += WS_POPUP

   ::Define2( FormName, Caption, x, y, w, h, 0, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
              nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
              minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, nil, nStyle, nStyleEx, ;
              0, lRtl, mdi, topmost, clientarea, restoreprocedure )

   if ! valtype( NotifyIconName ) $ "CM"
      NotifyIconName := ""
   Else
      ShowNotifyIcon( ::hWnd, .T. , LoadTrayIcon(GETINSTANCE(), NotifyIconName ), NotifyIconTooltip )
      ::NotifyIcon := NotifyIconName
      ::NotifyToolTip := NotifyIconToolTip
      ::NotifyIconLeftClick := NotifyIconLeftClick
   endif

Return Self

*-----------------------------------------------------------------------------*
METHOD Activate( lNoStop, oWndLoop ) CLASS TFormMain
*-----------------------------------------------------------------------------*
   ::lFirstActivate := .T.
Return ::Super:Activate( lNoStop, oWndLoop )

*-----------------------------------------------------------------------------*
METHOD Release() CLASS TFormMain
*-----------------------------------------------------------------------------*
   If ! ::lReleasing
      ::lReleasing := .T.
      ::DoEvent( ::OnRelease, 'WINDOW_RELEASE' )
      ReleaseAllWindows()
//   Else
//      MsgOOHGError("Release a window in its own 'on release' procedure or release the main window in any 'on release' procedure is not allowed. Program terminated" )
   EndIf
Return ::Super:Release()

*-----------------------------------------------------------------------------*
METHOD CheckInteractiveClose() CLASS TFormMain
*-----------------------------------------------------------------------------*
Local lRet := .T.
   If _OOHG_InteractiveClose == 3
      lRet := MsgYesNo( _OOHG_Messages( 1, 1 ), _OOHG_Messages( 1, 2 ) )
   Else
      lRet := ::Super:CheckInteractiveClose()
   EndIf
Return lRet




*-----------------------------------------------------------------------------*
CLASS TFormModal FROM TForm
*-----------------------------------------------------------------------------*
   DATA Type           INIT "M" READONLY
   DATA LockedForms    INIT {}
   DATA oPrevWindow    INIT nil

   METHOD Define
   METHOD Visible      SETGET
   METHOD Activate
   METHOD Release
   METHOD OnHideFocusManagement
ENDCLASS

*-----------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, Parent, nosize, nosysmenu, ;
               nocaption, InitProcedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, icon, FontName, ;
               FontSize, GotFocus, LostFocus, virtualheight, VirtualWidth, ;
               scrollleft, scrollright, scrollup, scrolldown, hscrollbox, ;
               vscrollbox, helpbutton, cursor, noshow, NoAutoRelease, ;
               InteractiveCloseProcedure, lRtl, modalsize, mdi, topmost, ;
               clientarea, restoreprocedure ) CLASS TFormModal
*-----------------------------------------------------------------------------*
Local nStyle := WS_POPUP, nStyleEx := 0
Local oParent, hParent

   If ValType( modalsize ) != "L"
      modalsize := .F.
   EndIf

   oParent := ::SearchParent( Parent )
   If ValType( oParent ) == "O"
      hParent := oParent:hWnd
   ELSE
      hParent := 0
      * Must have a parent!!!!!
   EndIf

   ::oPrevWindow := oParent

   ::Define2( FormName, Caption, x, y, w, h, hParent, helpbutton, ( ! modalsize ), ( ! modalsize ), nosize, nosysmenu, ;
              nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, nil, ;
              nil, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
              0, lRtl, mdi, topmost, clientarea, restoreprocedure )

Return Self

*-----------------------------------------------------------------------------*
METHOD Visible( lVisible ) CLASS TFormModal
*-----------------------------------------------------------------------------*
   IF VALTYPE( lVisible ) == "L"
      IF lVisible
         // Find Previous window
         If     aScan( _OOHG_aFormhWnd, GetActiveWindow() ) > 0
            ::oPrevWindow := GetFormObjectByHandle( GetActiveWindow() )
         ElseIf _OOHG_UserWindow != NIL .AND. ascan( _OOHG_aFormhWnd, _OOHG_UserWindow:hWnd ) > 0
            ::oPrevWindow := _OOHG_UserWindow
         ElseIf Len( _OOHG_ActiveModal ) != 0 .AND. ascan( _OOHG_aFormhWnd, ATAIL( _OOHG_ActiveModal ):hWnd ) > 0
            ::oPrevWindow := ATAIL( _OOHG_ActiveModal )
         ElseIf ::Parent != NIL .AND. ascan( _OOHG_aFormhWnd, ::Parent:hWnd ) > 0
            ::oPrevWindow := _OOHG_UserWindow
         ElseIf _OOHG_Main != nil
            ::oPrevWindow := _OOHG_Main
         Else
            ::oPrevWindow := NIL
            // Not mandatory MAIN
            // NO PREVIOUS DETECTED!
         EndIf

         AEVAL( _OOHG_aFormObjects, { |o| if( ! o:lInternal .AND. o:hWnd != ::hWnd .AND. IsWindowEnabled( o:hWnd ), ( AADD( ::LockedForms, o ), DisableWindow( o:hWnd ) ) , ) } )

         AADD( _OOHG_ActiveModal, Self )
         EnableWindow( ::hWnd )

         If ! ::SetFocusedSplitChild()
            ::SetActivationFocus()
         EndIf
      ELSE
         If IsWindowVisible( ::hWnd )
//// Why not?
////             If Len( _OOHG_ActiveModal ) == 0 .OR. ATAIL( _OOHG_ActiveModal ):hWnd <> ::hWnd
////                MsgOOHGError( "Non top modal windows can't be hide. Program terminated." )
//// // Testing...
//// //             ElseIf ::ActivateCount[ 1 ] > 1 .OR. ! ::ActivateCount == ATAIL( _OOHG_MessageLoops )
//// //                MsgOOHGError( "Modal windows can't be hidden when it have sub-windows. Program terminated." )
////             EndIf
         EndIf
      ENDIF
   ENDIF
RETURN ( ::Super:Visible := lVisible )

*-----------------------------------------------------------------------------*
METHOD Activate( lNoStop, oWndLoop ) CLASS TFormModal
*-----------------------------------------------------------------------------*
   // Not mandatory MAIN
   // If _OOHG_Main == nil
   //    MsgOOHGError("ACTIVATE WINDOW: Main Window Must be Activated In First ACTIVATE WINDOW Command. Program terminated" )
   // EndIf

   // Checks for non-stop window
   IF ValType( lNoStop ) != "L"
      lNoStop := .F.
   ENDIF
   IF lNoStop .AND. ValType( oWndLoop ) != "O" .AND. ValType( ::oPrevWindow ) == "O"
      oWndLoop := ::oPrevWindow
   ENDIF

   // Since this window disables all other windows, it must be visible!
   ::lVisible := .T.

Return ::Super:Activate( lNoStop, oWndLoop )

*-----------------------------------------------------------------------------*
METHOD Release() CLASS TFormModal
*-----------------------------------------------------------------------------*
   If ( Len( _OOHG_ActiveModal ) == 0 .OR. ATAIL( _OOHG_ActiveModal ):hWnd <> ::hWnd ) .AND. IsWindowVisible( ::hWnd )
      MsgOOHGError( "Non top modal windows can't be released. Program terminated *" + ::Name + "*" )
	EndIf
Return ::Super:Release()

*-----------------------------------------------------------------------------*
METHOD OnHideFocusManagement() CLASS TFormModal
*-----------------------------------------------------------------------------*

   // Re-enables locked forms
   AEVAL( ::LockedForms, { |o| IF( ValidHandler( o:hWnd ), EnableWindow( o:hWnd ), ) } )
   ::LockedForms := {}

   If ::oPrevWindow == nil
      // _OOHG_Main:SetFocus()
	Else
      ::oPrevWindow:SetFocus()
	EndIf

Return ::Super:OnHideFocusManagement()




*-----------------------------------------------------------------------------*
CLASS TFormInternal FROM TForm
*-----------------------------------------------------------------------------*
   DATA Type           INIT "I" READONLY
   DATA lInternal      INIT .T.

   METHOD Define
   METHOD Define2
   METHOD SizePos
   METHOD Row       SETGET
   METHOD Col       SETGET

   METHOD ContainerRow        BLOCK { |Self| IF( ::Container != NIL, ::Container:ContainerRow + ::Container:RowMargin, ::Parent:RowMargin ) + ::Row }
   METHOD ContainerCol        BLOCK { |Self| IF( ::Container != NIL, ::Container:ContainerCol + ::Container:ColMargin, ::Parent:ColMargin ) + ::Col }
ENDCLASS

*------------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, oParent, aRGB, fontname, fontsize, ;
               ClickProcedure, MouseDragProcedure, MouseMoveProcedure, ;
               PaintProcedure, noshow, icon, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, cursor, Focused, lRtl, mdi, clientarea ) CLASS TFormInternal
*------------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0

   ::SearchParent( oParent )
   ::Focused := ( ValType( Focused ) == "L" .AND. Focused )
   nStyle += WS_CHILD
   If _OOHG_SetControlParent()
      // This is not working when there's a RADIO control :(
      nStyleEx += WS_EX_CONTROLPARENT
   EndIf

   ::Define2( FormName, Caption, x, y, w, h, ::Parent:hWnd, .F., .T., .T., .T., .T., ;
              .T., virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, nil, ;
              nil, nil, nil, nil, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, nil, nil, nStyle, nStyleEx, ;
              0, lRtl, mdi,, clientarea, nil )

Return Self

*------------------------------------------------------------------------------*
METHOD Define2( FormName, Caption, x, y, w, h, Parent, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
                nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
                icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
                minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
                MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
                nWindowType, lRtl, mdi, topmost, clientarea, restoreprocedure ) CLASS TFormInternal
*------------------------------------------------------------------------------*

   ::Super:Define2( FormName, Caption, x, y, w, h, Parent, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
                    nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
                    icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
                    minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
                    MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
                    nWindowType, lRtl, mdi, topmost, clientarea, restoreprocedure )

   ::ActivateCount[ 1 ] += 999
   aAdd( ::Parent:SplitChildList, Self )
   aAdd( ::Parent:BrowseList, Self )
   ::Parent:AddControl( Self )
   ::Active := .T.
   If ::lVisible
      ShowWindow( ::hWnd )
   EndIf

   ::ContainerhWndValue := ::hWnd

Return Self

*------------------------------------------------------------------------------*
METHOD SizePos( nRow, nCol, nWidth, nHeight ) CLASS TFormInternal
*------------------------------------------------------------------------------*
Local uRet
   if valtype( nCol ) == "N"
      ::nCol := nCol
   endif
   if valtype( nRow ) == "N"
      ::nRow := nRow
   endif
   if valtype( nWidth ) != "N"
      nWidth := ::nWidth
   else
      ::nWidth := nWidth
   endif
   if valtype( nHeight ) != "N"
      nHeight := ::nHeight
   else
      ::nHeight := nHeight
   endif

   uRet := MoveWindow( ::hWnd, ::ContainerCol, ::ContainerRow, nWidth, nHeight, .t. )
   ValidateScrolls( Self, .T. )
Return uRet

*------------------------------------------------------------------------------*
METHOD Col( nCol ) CLASS TFormInternal
*------------------------------------------------------------------------------*
   IF PCOUNT() > 0
      ::SizePos( , nCol )
   ENDIF
RETURN ::nCol

*------------------------------------------------------------------------------*
METHOD Row( nRow ) CLASS TFormInternal
*------------------------------------------------------------------------------*
   IF PCOUNT() > 0
      ::SizePos( nRow )
   ENDIF
RETURN ::nRow





*-----------------------------------------------------------------------------*
CLASS TFormSplit FROM TFormInternal
*-----------------------------------------------------------------------------*
   DATA Type           INIT "X" READONLY

   METHOD Define
ENDCLASS

*-----------------------------------------------------------------------------*
METHOD Define( FormName, w, h, break, grippertext, nocaption, title, aRGB, ;
               fontname, fontsize, gotfocus, lostfocus, virtualheight, ;
               VirtualWidth, Focused, scrollleft, scrollright, scrollup, ;
               scrolldown, hscrollbox, vscrollbox, cursor, lRtl, mdi, ;
               clientarea ) CLASS TFormSplit
*-----------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0

   ::SearchParent()
   ::Focused := ( ValType( Focused ) == "L" .AND. Focused )
   nStyle += WS_CHILD
   nStyleEx += WS_EX_STATICEDGE + WS_EX_TOOLWINDOW
   If _OOHG_SetControlParent()
      // This is not working when there's a RADIO control :(
      nStyleEx += WS_EX_CONTROLPARENT
   EndIf

   If ! ::SetSplitBoxInfo()
      MsgOOHGError( "SplitChild Windows Can be Defined Only Inside SplitBox. Program terminated." )
   EndIf

   ::Define2( FormName, Title, 0, 0, w, h, ::Parent:hWnd, .F., .F., .F., .F., .F., ;
              nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              nil, .F., gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, nil, ;
              nil, nil, nil, nil, nil, nil, ;
              nil, nil, nil, .F., nStyle, nStyleEx, ;
              1, lRtl, mdi, .F., clientarea, nil )

   If ::Container:lForceBreak .AND. ! ::Container:lInverted
      Break := .T.
   EndIf
   ::SetSplitBoxInfo( Break, GripperText )
   ::Container:AddControl( Self )

Return Self

*-----------------------------------------------------------------------------*
CLASS TFormMDIClient FROM TFormInternal
*-----------------------------------------------------------------------------*
   DATA Type           INIT "D" READONLY

   METHOD Define
ENDCLASS

*------------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, MouseDragProcedure, ;
               ClickProcedure, MouseMoveProcedure, aRGB, PaintProcedure, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, cursor, oParent, Focused, lRtl, ;
               clientarea ) CLASS TFormMDIClient
*------------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0

   ::Focused := ( ValType( Focused ) == "L" .AND. Focused )
   ::SearchParent( oParent )

* ventana MDI FRAME
*      nStyle   += WS_CLIPSIBLINGS + WS_CLIPCHILDREN // + WS_THICKFRAME
   nStyle   += WS_CHILD + WS_CLIPCHILDREN

   ::Define2( FormName, Caption, x, y, w, h, ::Parent:hWnd, .F., .T., .T., .T., .T., ;
              .T., virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, .F., gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, nil, ;
              nil, nil, nil, nil, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, nil, .F., nStyle, nStyleEx, ;
              2, lRtl, .F.,, clientarea, nil )

   ::Parent:hWndClient := ::hWnd
   ::hWndClient := ::hWnd

Return Self





*-----------------------------------------------------------------------------*
CLASS TFormMDIChild FROM TFormInternal
*-----------------------------------------------------------------------------*
   DATA Type           INIT "L" READONLY

   METHOD Define
ENDCLASS

*------------------------------------------------------------------------------*
METHOD Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, NoAutoRelease, oParent, ;
               InteractiveCloseProcedure, Focused, lRtl, clientarea, ;
               restoreprocedure ) CLASS TFormMDIChild
*------------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0

   ::Focused := ( ValType( Focused ) == "L" .AND. Focused )
   ::SearchParent( oParent )

   nStyle   += WS_CHILD
   nStyleEx += WS_EX_MDICHILD

   // If MDIclient window doesn't exists, create it.
   If ! ValidHandler( ::Parent:hWndClient )
      oParent := TFormMDIClient():Define( ,,,,,,,,,,,,,,,,,,,,,,,,, ::Parent )
      ::SearchParent( oParent )
   EndIf

   ::Define2( FormName, Caption, x, y, w, h, ::Parent:hWnd, helpbutton, nominimize, nomaximize, nosize, nosysmenu, ;
              nocaption, virtualheight, virtualwidth, hscrollbox, vscrollbox, fontname, fontsize, aRGB, cursor, ;
              icon, noshow, gotfocus, lostfocus, scrollleft, scrollright, scrollup, scrolldown, maximizeprocedure, ;
              minimizeprocedure, initprocedure, ReleaseProcedure, SizeProcedure, ClickProcedure, PaintProcedure, ;
              MouseMoveProcedure, MouseDragProcedure, InteractiveCloseProcedure, NoAutoRelease, nStyle, nStyleEx, ;
              3, lRtl,,, clientarea, restoreprocedure )

Return Self





*------------------------------------------------------------------------------*
FUNCTION DefineWindow( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
                       nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
                       MouseDragProcedure, SizeProcedure, ClickProcedure, ;
                       MouseMoveProcedure, aRGB, PaintProcedure, noshow, topmost, ;
                       icon, fontname, fontsize, NotifyIconName, NotifyIconTooltip, ;
                       NotifyIconLeftClick, GotFocus, LostFocus, Virtualheight, ;
                       VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
                       hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
                       minimizeprocedure, cursor, NoAutoRelease, oParent, ;
                       InteractiveCloseProcedure, Focused, Break, GripperText, lRtl, ;
                       main, splitchild, child, modal, modalsize, mdi, internal, ;
                       mdichild, mdiclient, subclass, clientarea, restoreprocedure )
*------------------------------------------------------------------------------*
Local nStyle := 0, nStyleEx := 0
Local Self
Local aError := {}

///////////////////// Check for non-"implemented" parameters at Tform's subclasses....

   If ValType( main ) != "L"
      main := .F.
   ElseIf main
      AADD( aError, "MAIN" )
   EndIf
   If ValType( splitchild ) != "L"
      splitchild := .F.
   ElseIf splitchild
      AADD( aError, "SPLITCHILD" )
   EndIf
   If ValType( child ) != "L"
      child := .F.
   ElseIf child
      AADD( aError, "CHILD" )
   EndIf
   If ValType( modal ) != "L"
      modal := .F.
   ElseIf modal
      AADD( aError, "MODAL" )
   EndIf
   If ValType( modalsize ) != "L"
      modalsize := .F.
   ElseIf modalsize
      AADD( aError, "MODALSIZE" )
   EndIf
   If ValType( mdiclient ) != "L"
      mdiclient := .F.
   ElseIf mdiclient
      AADD( aError, "MDICLIENT" )
   EndIf
   If ValType( mdichild ) != "L"
      mdichild := .F.
   ElseIf mdichild
      AADD( aError, "MDICHILD" )
   EndIf
   If ValType( internal ) != "L"
      internal := .F.
   ElseIf internal
      AADD( aError, "INTERNAL" )
   EndIf

   if Len( aError ) > 1
      MsgOOHGError( "Window: " + aError[ 1 ] + " and " + aError[ 2 ] + " clauses can't be used Simultaneously. Program Terminated." )
   endif

   If main
      Self := _OOHG_SelectSubClass( TFormMain(), subclass )
      ::Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, topmost, ;
               icon, fontname, fontsize, NotifyIconName, NotifyIconTooltip, ;
               NotifyIconLeftClick, GotFocus, LostFocus, virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, InteractiveCloseProcedure, lRtl, mdi, ;
               clientarea, restoreprocedure )
   ElseIf splitchild
      Self := _OOHG_SelectSubClass( TFormSplit(), subclass )
      ::Define( FormName, w, h, break, grippertext, nocaption, caption, aRGB, ;
               fontname, fontsize, gotfocus, lostfocus, virtualheight, ;
               VirtualWidth, Focused, scrollleft, scrollright, scrollup, ;
               scrolldown, hscrollbox, vscrollbox, cursor, lRtl, mdi, clientarea )
   ElseIf modal
      Self := _OOHG_SelectSubClass( TFormModal(), subclass )
      ::Define( FormName, Caption, x, y, w, h, oParent, .T., nosysmenu, ;
               nocaption, InitProcedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, icon, FontName, ;
               FontSize, GotFocus, LostFocus, virtualheight, VirtualWidth, ;
               scrollleft, scrollright, scrollup, scrolldown, hscrollbox, ;
               vscrollbox, helpbutton, cursor, noshow, NoAutoRelease, ;
               InteractiveCloseProcedure, lRtl, .F., mdi, topmost, clientarea, ;
               restoreprocedure )
   ElseIf modalsize
      Self := _OOHG_SelectSubClass( TFormModal(), subclass )
      ::Define( FormName, Caption, x, y, w, h, oParent, nosize, nosysmenu, ;
               nocaption, InitProcedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, icon, FontName, ;
               FontSize, GotFocus, LostFocus, virtualheight, VirtualWidth, ;
               scrollleft, scrollright, scrollup, scrolldown, hscrollbox, ;
               vscrollbox, helpbutton, cursor, noshow, NoAutoRelease, ;
               InteractiveCloseProcedure, lRtl, .F., mdi, topmost, clientarea, ;
               restoreprocedure )
   ElseIf mdiclient
      Self := _OOHG_SelectSubClass( TFormMDIClient(), subclass )
      ::Define( FormName, Caption, x, y, w, h, MouseDragProcedure, ;
               ClickProcedure, MouseMoveProcedure, aRGB, PaintProcedure, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, cursor, oParent, Focused, lRtl, clientarea )
   ElseIf mdichild
      Self := _OOHG_SelectSubClass( TFormMDIChild(), subclass )
      ::Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, NoAutoRelease, oParent, ;
               InteractiveCloseProcedure, Focused, lRtl, clientarea, restoreprocedure )
   ElseIf internal
      Self := _OOHG_SelectSubClass( TFormInternal(), subclass )
      ::Define( FormName, Caption, x, y, w, h, oParent, aRGB, fontname, fontsize, ;
               ClickProcedure, MouseDragProcedure, MouseMoveProcedure, ;
               PaintProcedure, noshow, icon, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, cursor, Focused, lRtl, mdi, clientarea )
   Else // Child and "S"
      Self := _OOHG_SelectSubClass( TForm(), subclass )
      ::Define( FormName, Caption, x, y, w, h, nominimize, nomaximize, nosize, ;
               nosysmenu, nocaption, initprocedure, ReleaseProcedure, ;
               MouseDragProcedure, SizeProcedure, ClickProcedure, ;
               MouseMoveProcedure, aRGB, PaintProcedure, noshow, topmost, ;
               icon, fontname, fontsize, GotFocus, LostFocus, Virtualheight, ;
               VirtualWidth, scrollleft, scrollright, scrollup, scrolldown, ;
               hscrollbox, vscrollbox, helpbutton, maximizeprocedure, ;
               minimizeprocedure, cursor, NoAutoRelease, oParent, ;
               InteractiveCloseProcedure, lRtl, child, mdi, clientarea, ;
               restoreprocedure )
   EndIf

   if ! valtype( NotifyIconName ) $ "CM"
      NotifyIconName := ""
   Else
      ShowNotifyIcon( ::hWnd, .T. , LoadTrayIcon(GETINSTANCE(), NotifyIconName ), NotifyIconTooltip )
      ::NotifyIcon := NotifyIconName
      ::NotifyToolTip := NotifyIconToolTip
      ::NotifyIconLeftClick := NotifyIconLeftClick
   endif

Return Self

*-----------------------------------------------------------------------------*
Procedure _KillAllKeys()
*-----------------------------------------------------------------------------*
Local I, hWnd
   FOR I := 1 TO LEN( _OOHG_aFormhWnd )
      hWnd := _OOHG_aFormObjects[ I ]:hWnd
      AEVAL( _OOHG_aFormObjects[ I ]:aHotKeys, { |a| ReleaseHotKey( hWnd, a[ HOTKEY_ID ] ) } )
   NEXT
Return

// Initializes C variables
*-----------------------------------------------------------------------------*
Procedure _OOHG_Init_C_Vars()
*-----------------------------------------------------------------------------*
   TForm()
   _OOHG_Init_C_Vars_C_Side( _OOHG_aFormhWnd, _OOHG_aFormObjects )
Return

*-----------------------------------------------------------------------------*
Function GetFormObject( FormName )
*-----------------------------------------------------------------------------*
Local mVar
   mVar := '_' + FormName
Return IF( Type( mVar ) == "O", &mVar, TForm() )

*-----------------------------------------------------------------------------*
Function GetExistingFormObject( FormName )
*-----------------------------------------------------------------------------*
Local mVar
   mVar := '_' + FormName
   If ! Type( mVar ) == "O"
      MsgOOHGError( "Window " + FormName + " not defined. Program Terminated." )
   EndIf
Return &mVar

*-----------------------------------------------------------------------------*
Function GetWindowType( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Type

*-----------------------------------------------------------------------------*
Function _IsWindowActive ( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Active

*-----------------------------------------------------------------------------*
Function _IsWindowDefined ( FormName )
*-----------------------------------------------------------------------------*
Local mVar
mVar := '_' + FormName
Return ( Type( mVar ) == "O" )

*-----------------------------------------------------------------------------*
Function GetFormName( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Name

*-----------------------------------------------------------------------------*
Function GetFormToolTipHandle( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):ToolTipHandle

*-----------------------------------------------------------------------------*
Function GetFormHandle( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):hWnd

*-----------------------------------------------------------------------------*
Function ReleaseAllWindows()
*-----------------------------------------------------------------------------*
Local i, oWnd

//   If _OOHG_ThisEventType == 'WINDOW_RELEASE'
//      MsgOOHGError( "Release a window in its own 'on release' procedure or release the main window in any 'on release' procedure is not allowed. Program terminated." )
//   EndIf

   For i = 1 to len ( _OOHG_aFormhWnd )
      oWnd := _OOHG_aFormObjects[ i ]
      if oWnd:Active

         If ! oWnd:lReleasing
            oWnd:lReleasing := .T.
            oWnd:DoEvent( oWnd:OnRelease, 'WINDOW_RELEASE' )
         EndIf

         if .Not. Empty ( oWnd:NotifyIcon )
            oWnd:NotifyIcon := ''
            ShowNotifyIcon( oWnd:hWnd, .F., NIL, NIL )
			EndIf

		Endif

      aeval( oWnd:aHotKeys, { |a| ReleaseHotKey( oWnd:hWnd, a[ HOTKEY_ID ] ) } )
      oWnd:aHotKeys := {}

	Next i

	dbcloseall()

   ExitProcess(0)

Return Nil

*-----------------------------------------------------------------------------*
Function _ReleaseWindow( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Release()

*-----------------------------------------------------------------------------*
Function _ShowWindow( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Show()

*-----------------------------------------------------------------------------*
Function _HideWindow( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Hide()

*-----------------------------------------------------------------------------*
Function _CenterWindow ( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Center()

*-----------------------------------------------------------------------------*
Function _RestoreWindow ( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Restore()

*-----------------------------------------------------------------------------*
Function _MaximizeWindow ( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Maximize()

*-----------------------------------------------------------------------------*
Function _MinimizeWindow ( FormName )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):Minimize()

*-----------------------------------------------------------------------------*
Function _SetWindowSizePos( FormName , row , col , width , height )
*-----------------------------------------------------------------------------*
Return GetFormObject( FormName ):SizePos( row , col , width , height )

*-----------------------------------------------------------------------------*
Function _EndWindow()
*-----------------------------------------------------------------------------*
   If Len( _OOHG_ActiveForm ) > 0
      _OOHG_DeleteArrayItem( _OOHG_ActiveForm, Len( _OOHG_ActiveForm ) )
	EndIf
Return Nil

*-----------------------------------------------------------------------------*
Function InputBox ( cInputPrompt , cDialogCaption , cDefaultValue , nTimeout , cTimeoutValue , lMultiLine )
*-----------------------------------------------------------------------------*

	Local RetVal , mo

	DEFAULT cInputPrompt	TO ""
	DEFAULT cDialogCaption	TO ""
	DEFAULT cDefaultValue	TO ""

	RetVal := ''

   If ValType (lMultiLine) == 'L' .AND. lMultiLine
      mo := 150
	Else
		mo := 0
	EndIf

	DEFINE WINDOW _InputBox 		;
		AT 0,0 				;
		WIDTH 350 			;
		HEIGHT 115 + mo	+ GetTitleHeight() ;
		TITLE cDialogCaption  		;
		MODAL 				;
		NOSIZE 				;
      FONT 'Arial'      ;
      SIZE 10           ;
      BACKCOLOR ( GetFormObjectByHandle( GetActiveWindow() ):BackColor )

      ON KEY ESCAPE ACTION ( _OOHG_DialogCancelled := .T. , if(iswindowactive(_Inputbox), _InputBox.Release ,nil)   )

		@ 07,10 LABEL _Label		;
			VALUE cInputPrompt	;
			WIDTH 280
// JK
                If ValType (lMultiLine) != 'U' .and. lMultiLine == .T.
                @ 30,10 EDITBOX _TextBox	;
			VALUE cDefaultValue	;
			HEIGHT 26 + mo		;
			WIDTH 320
                else
		@ 30,10 TEXTBOX _TextBox	;
			VALUE cDefaultValue	;
			HEIGHT 26 + mo		;
			WIDTH 320		;
         ON ENTER ( _OOHG_DialogCancelled := .F. , RetVal := _InputBox._TextBox.Value , if(iswindowactive(_Inputbox), _InputBox.Release ,nil)   )

                endif
//
		@ 67+mo,120 BUTTON _Ok		;
			CAPTION if( Set ( _SET_LANGUAGE ) == 'ES', 'Aceptar' ,'Ok' )		;
         ACTION ( _OOHG_DialogCancelled := .F. , RetVal := _InputBox._TextBox.Value , if(iswindowactive(_Inputbox), _InputBox.Release ,nil)   )

		@ 67+mo,230 BUTTON _Cancel		;
			CAPTION if( Set ( _SET_LANGUAGE ) == 'ES', 'Cancelar', 'Cancel'	);
         ACTION   ( _OOHG_DialogCancelled := .T. , if(iswindowactive(_Inputbox), _InputBox.Release ,nil)   )

			If ValType (nTimeout) != 'U'

				If ValType (cTimeoutValue) != 'U'

					DEFINE TIMER _InputBox ;
					INTERVAL nTimeout ;
					ACTION  ( RetVal := cTimeoutValue , if(iswindowactive(_Inputbox), _InputBox.Release ,nil)   )

				Else

					DEFINE TIMER _InputBox ;
					INTERVAL nTimeout ;
					ACTION _InputBox.Release

				EndIf

			EndIf

	END WINDOW

	_InputBox._TextBox.SetFocus

	CENTER WINDOW _InputBox

	ACTIVATE WINDOW _InputBox

Return ( RetVal )

*-----------------------------------------------------------------------------*
Function _SetWindowRgn(name,col,row,w,h,lx)
*-----------------------------------------------------------------------------*
Return c_SetWindowRgn( GetFormHandle( name ), col, row, w, h, lx )

*-----------------------------------------------------------------------------*
Function _SetPolyWindowRgn(name,apoints,lx)
*-----------------------------------------------------------------------------*
local apx:={},apy:={}

      aeval(apoints,{|x| aadd(apx,x[1]), aadd(apy,x[2])})

Return c_SetPolyWindowRgn( GetFormHandle( name ), apx, apy, lx )

*-----------------------------------------------------------------------------*
Procedure _SetNextFocus()
*-----------------------------------------------------------------------------*
Local oCtrl , NextControlHandle

	NextControlHandle := GetNextDlgTabITem ( GetActiveWindow() , GetFocus() , 0 )
   oCtrl := GetControlObjectByHandle( NextControlHandle )
   if oCtrl:hWnd == NextControlHandle
      oCtrl:SetFocus()
   else
		InsertTab()
   endif

Return

*-----------------------------------------------------------------------------*
Function _ActivateWindow( aForm, lNoWait )
*-----------------------------------------------------------------------------*
Local z, aForm2, oWndActive, oWnd, lModal

   // Not mandatory MAIN
   // If _OOHG_Main == nil
   //    MsgOOHGError( "MAIN WINDOW not defined. Program Terminated." )
   // EndIf

* Testing... it allows to create non-modal windows when modal windows are active.
* The problem is, what should do when modal window is ... disabled? hidden? WM_CLOSE? WM_DESTROY?
/*
   // Multiple activation can't be used when modal window is active
   If len( aForm ) > 1 .AND. Len( _OOHG_ActiveModal ) != 0
      MsgOOHGError( "Multiple Activation can't be used when a modal window is active. Program Terminated" )
   Endif
*/

   aForm2 := ACLONE( aForm )

   // Validates NOWAIT flag
   IF ValType( lNoWait ) != "L"
      lNoWait := .F.
   ENDIF
   oWndActive := IF( lNoWait .AND. ValType( _OOHG_Main ) == "O", _OOHG_Main, GetFormObject( aForm2[ 1 ] ) )

   // Looks for MAIN window
   If _OOHG_Main != NIL
      z := ASCAN( aForm2, { |c| GetFormObject( c ):hWnd == _OOHG_Main:hWnd } )
      IF z != 0
         AADD( aForm2, nil )
         AINS( aForm2, 1 )
         aForm2[ 1 ] := aForm2[ z + 1 ]
         _OOHG_DeleteArrayItem( aForm2, z + 1 )
         IF lNoWait
            oWndActive := GetFormObject( aForm2[ 1 ] )
         EndIf
      ENDIF
   ENDIF

   // Activate windows
   lModal := .F.
   FOR z := 1 TO Len( aForm2 )
      oWnd := GetFormObject( aForm2[ z ] )
      IF oWnd:Type == "M" .AND. oWnd:lVisible
         IF lModal
            MsgOOHGError( "ACTIVATE WINDOW: Only one initially visible modal window allowed. Program terminated" )
         ENDIF
         lModal := .T.
      ENDIF
      oWnd:Activate( .T., oWndActive )
   NEXT

   If ! lNoWait
      GetFormObject( aForm2[ 1 ] ):MessageLoop()
   Endif

Return Nil

*-----------------------------------------------------------------------------*
Function _ActivateAllWindows()
*-----------------------------------------------------------------------------*
Local i
Local aForm := {}, oWnd
Local MainName := ''

   // Not mandatory MAIN
   // If _OOHG_Main == nil
   //    MsgOOHGError( "MAIN WINDOW not defined. Program Terminated." )
   // EndIf

	* If Already Active Windows Abort Command

   If ascan( _OOHG_aFormObjects, { |o| o:Active .AND. ! o:lInternal } ) > 0
      MsgOOHGError( "ACTIVATE WINDOW ALL: This Command Should Be Used At Application Startup Only. Program terminated" )
	EndIf

// WHY???   * Force NoShow And NoAutoRelease Styles For Non Main Windows
	* ( Force AutoRelease And Visible For Main )

   For i := 1 To LEN( _OOHG_aFormObjects )
      oWnd := _OOHG_aFormObjects[ i ]
      If oWnd:hWnd == _OOHG_Main:hWnd
         oWnd:lVisible := .T.
         oWnd:AutoRelease := .T.
         MainName := oWnd:Name
      ElseIf ! oWnd:lInternal
//         oWnd:lVisible := .F.
//         oWnd:AutoRelease := .F.
         aadd( aForm , oWnd:Name )
      EndIf
	Next i

	aadd ( aForm , MainName )

	* Check For Error And Call Activate Window Command

   If Empty( MainName )
      MsgOOHGError( "ACTIVATE WINDOW ALL: Main Window Not Defined. Program terminated" )
   ElseIf Len( aForm ) == 0
      MsgOOHGError( "ACTIVATE WINDOW ALL: No Windows Defined. Program terminated" )
	Else
      _ActivateWindow( aForm )
	EndIf

Return Nil

*------------------------------------------------------------------------------*
Procedure _PushEventInfo
*------------------------------------------------------------------------------*
   aAdd( _OOHG_aEventInfo, { _OOHG_ThisForm, _OOHG_ThisEventType, _OOHG_ThisType, _OOHG_ThisControl, _OOHG_ThisObject } )
Return

*------------------------------------------------------------------------------*
Procedure _PopEventInfo()
*------------------------------------------------------------------------------*
Local l
   l := Len( _OOHG_aEventInfo )
   If l > 0
      _OOHG_ThisForm      := _OOHG_aEventInfo[ l ][ 1 ]
      _OOHG_ThisEventType := _OOHG_aEventInfo[ l ][ 2 ]
      _OOHG_ThisType      := _OOHG_aEventInfo[ l ][ 3 ]
      _OOHG_ThisControl   := _OOHG_aEventInfo[ l ][ 4 ]
      _OOHG_ThisObject    := _OOHG_aEventInfo[ l ][ 5 ]
      aSize( _OOHG_aEventInfo, l - 1 )
	Else
      _OOHG_ThisForm      := nil
      _OOHG_ThisType      := ''
      _OOHG_ThisEventType := ''
      _OOHG_ThisControl   := nil
      _OOHG_ThisObject    := nil
	EndIf
Return

Function SetInteractiveClose( nValue )
Local nRet := _OOHG_InteractiveClose
   If ValType( nValue ) == "N" .AND. nValue >= 0 .AND. nValue <= 3
      _OOHG_InteractiveClose := INT( nValue )
   EndIf
Return nRet

Function SetAppHotKey( nKey, nFlags, bAction )
Return _OOHG_SetKey( _OOHG_HotKeys, nKey, nFlags, bAction )

Function _OOHG_MacroCall( cMacro )
Local uRet, oError
   oError := ERRORBLOCK()
   ERRORBLOCK( { | e | _OOHG_MacroCall_Error( e ) } )
   BEGIN SEQUENCE
      uRet := &cMacro
   RECOVER
      uRet := nil
   END SEQUENCE
   ERRORBLOCK( oError )
Return uRet

Static Function _OOHG_MacroCall_Error( oError )
   BREAK oError
RETURN 1

FUNCTION ExitProcess( nExit )
   DBCloseAll()
RETURN _ExitProcess2( nExit )

EXTERN IsXPThemeActive, _OOHG_Eval, EVAL
EXTERN _OOHG_ShowContextMenus, _OOHG_GlobalRTL, _OOHG_NestedSameEvent
EXTERN _SetTooltipBackcolor, _SetTooltipForecolor
EXTERN ValidHandler

#pragma BEGINDUMP

typedef LONG ( * CALL_ISTHEMEACTIVE )( void );

HB_FUNC( ISXPTHEMEACTIVE )
{
   BOOL bResult = FALSE;
   HMODULE hInstDLL;
   CALL_ISTHEMEACTIVE dwProcAddr;
   LONG lResult;

   OSVERSIONINFO os;

   os.dwOSVersionInfoSize = sizeof( os );

   if( GetVersionEx( &os ) && os.dwPlatformId == VER_PLATFORM_WIN32_NT && os.dwMajorVersion == 5 && os.dwMinorVersion == 1 )
   {
      hInstDLL = LoadLibrary( "UXTHEME.DLL" );
      if( hInstDLL )
      {
         dwProcAddr = ( CALL_ISTHEMEACTIVE ) GetProcAddress( hInstDLL, "IsThemeActive" );
         if( dwProcAddr )
         {
            lResult = ( dwProcAddr )();
            if( lResult )
            {
               bResult = TRUE;
            }
         }

         FreeLibrary( hInstDLL );
      }
   }

   hb_retl( bResult );
}

HB_FUNC( _OOHG_EVAL )
{
   if( ISBLOCK( 1 ) )
   {
      HB_FUN_EVAL();
   }
   else
   {
      hb_ret();
   }
}

HB_FUNC( _OOHG_SHOWCONTEXTMENUS )
{
   if( ISLOG( 1 ) )
   {
      _OOHG_ShowContextMenus = hb_parl( 1 );
   }
   hb_retl( _OOHG_ShowContextMenus );
}

HB_FUNC( _OOHG_GLOBALRTL )
{
   if( ISLOG( 1 ) )
   {
      _OOHG_GlobalRTL = hb_parl( 1 );
   }
   hb_retl( _OOHG_GlobalRTL );
}

HB_FUNC( _OOHG_NESTEDSAMEEVENT )
{
   if( ISLOG( 1 ) )
   {
      _OOHG_NestedSameEvent = hb_parl( 1 );
   }
   hb_retl( _OOHG_NestedSameEvent );
}

HB_FUNC( _SETTOOLTIPBACKCOLOR )
{
   _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &_OOHG_TooltipBackcolor, ( hb_pcount() >= 1 ) );
}

HB_FUNC( _SETTOOLTIPFORECOLOR )
{
   _OOHG_DetermineColorReturn( hb_param( 1, HB_IT_ANY ), &_OOHG_TooltipForecolor, ( hb_pcount() >= 1 ) );
}

HB_FUNC( VALIDHANDLER )
{
   HWND hWnd;
   hWnd = HWNDparam( 1 );
   hb_retl( ValidHandler( hWnd ) );
}

HB_FUNC( _OOHG_GETMOUSECOL )
{
   hb_retni( _OOHG_MouseCol );
}

HB_FUNC( _OOHG_GETMOUSEROW )
{
   hb_retni( _OOHG_MouseRow );
}

#pragma ENDDUMP

Function _OOHG_GetArrayItem( uaArray, nItem, uExtra1, uExtra2 )
Local uRet
   IF ValType( uaArray ) != "A"
      uRet := uaArray
   ElseIf LEN( uaArray ) >= nItem .AND. nItem >= 1
      uRet := uaArray[ nItem ]
   Else
      uRet := NIL
   ENDIF
   IF ValType( uRet ) == "B"
      uRet := Eval( uRet, nItem, uExtra1, uExtra2 )
   ENDIF
Return uRet

Function _OOHG_DeleteArrayItem( aArray, nItem )
#ifdef __XHARBOUR__
   Return ADel( aArray, nItem, .T. )
#else
   IF ValType( aArray ) == "A" .AND. Len( aArray ) >= nItem
      ADel( aArray, nItem )
      ASize( aArray, Len( aArray ) - 1 )
   ENDIF
   Return aArray
#endif

FUNCTION _OOHG_SetKey( aKeys, nKey, nFlags, bAction, nId )
Local nPos, uRet := nil
   nPos := ASCAN( aKeys, { |a| a[ HOTKEY_KEY ] == nKey .AND. a[ HOTKEY_MOD ] == nFlags } )
   If nPos > 0
      uRet := aKeys[ nPos ][ HOTKEY_ACTION ]
   EndIf
   If PCOUNT() > 2
      If ValType( bAction ) == "B"
         If ValType( nId ) != "N"
            nId := 0
         EndIf
         If nPos > 0
            aKeys[ nPos ] := { nId, nFlags, nKey, bAction }
         Else
            AADD( aKeys, { nId, nFlags, nKey, bAction } )
         EndIf
      Else
         If nPos > 0
            _OOHG_DeleteArrayItem( aKeys, nPos )
         EndIf
      Endif
   EndIf
Return uRet

FUNCTION _OOHG_SetbKeyDown( bKeyDown )
Local uRet
   uRet := _OOHG_bKeyDown
   If ValType( bKeyDown ) == "B"
      _OOHG_bKeyDown := bKeyDown
   ElseIf PCOUNT() > 0
      _OOHG_bKeyDown := nil
   EndIf
Return uRet

PROCEDURE _OOHG_CallDump( cTitle )
LOCAL nLevel, cText
   cText := ""
   nLevel := 1
   DO WHILE ! Empty( PROCNAME( nLevel ) )
      IF nLevel > 1
         cText += CHR( 13 ) + CHR( 10 )
      ENDIF
      cText += PROCNAME( nLevel ) + "(" + LTRIM( STR( PROCLINE( nLevel ) ) ) + ")"
      nLevel++
   ENDDO
   MSGINFO( cText, cTitle )
Return

// PATCH :(
FUNCTION _OOHG_SetControlParent( lNewState )
STATIC lState := .F.
   If ValType( lNewState ) == "L"
      lState := lNewState
   EndIf
RETURN lState
