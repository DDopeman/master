enum USPAnimation
{
	USP_IDLE = 0,
	USP_SHOOT1,
	USP_SHOOT2,
	USP_SHOOT3,
	USP_SHOOTLAST,
	USP_RELOAD,
	USP_DRAW,
	USP_ADD_SILENCER,
	USP_IDLE_UNSIL,
	USP_SHOOT1_UNSIL,
	USP_SHOOT2_UNSIL,
	USP_SHOOT3_UNSIL,
	USP_SHOOTLAST_UNSIL,
	USP_RELOAD_UNSIL,
	USP_DRAW_UNSIL,
	USP_DETACH_SILENCER
};

enum SilencedMode
{
	MODE_NOSILENCER = 0,
	MODE_SILENCER
};

const int USP_DEFAULT_GIVE		= 24;
const int USP_MAX_CARRY			= 100;
const int USP_MAX_CLIP			= 12;
const int USP_WEIGHT			= 5;

class weapon_usp : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null; // VXP

	float m_flNextAnimTime;
	int g_iCurrentMode;
	int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/rngstuff/kuilu/weapons/w_p228.mdl" );
		
		self.m_iDefaultAmmo = USP_DEFAULT_GIVE;
		g_iCurrentMode = 0;
		
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/v_p228.mdl");
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/w_p228.mdl");
		g_Game.PrecacheModel( "models/rngstuff/kuilu/weapons/p_p228.mdl");
		
		m_iShell = g_Game.PrecacheModel ( "models/shell.mdl");
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/dryfire1.wav" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_fire.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_fire_sil.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_silencer_on.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_silencer_off.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_clipout.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_clipin.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_slide.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_slidepull.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_slide_sil.ogg" );
		g_Game.PrecacheGeneric( "sound/" + "rng/kuilu/weapons/p228_slidepull_sil.ogg" );
		
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );
		
		g_SoundSystem.PrecacheSound( "weapons/dryfire1.wav" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_fire.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_fire_sil.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_silencer_on.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_silencer_off.ogg");
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_clipout.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_clipin.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_slide.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_slidepull.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_slide_sil.ogg" );
		g_SoundSystem.PrecacheSound( "rng/kuilu/weapons/p228_slidepull_sil.ogg" );
		
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud1.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/640hud4.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/crosshairs.spr" );
		g_Game.PrecacheGeneric( "sprites/" + "kuilu/weapon_usp.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= USP_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= USP_MAX_CLIP;
		info.iSlot		= 1;
		info.iPosition	= 7;
		info.iFlags		= 0;
		info.iWeight	= USP_WEIGHT;
		
		return true;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dryfire1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer ( pPlayer ) )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();

			@m_pPlayer = pPlayer; // VXP
			return true;
		}
		
		return false;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	bool Deploy()
	{
		bool bResult;
		{

		if ( g_iCurrentMode == MODE_SILENCER )
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/rngstuff/kuilu/weapons/v_p228.mdl" ), self.GetP_Model( "models/rngstuff/kuilu/weapons/p_p228.mdl" ), USP_DRAW, "onehanded" );
		}
		else
		{
			bResult = self.DefaultDeploy ( self.GetV_Model( "models/rngstuff/kuilu/weapons/v_p228.mdl" ), self.GetP_Model( "models/rngstuff/kuilu/weapons/p_p228.mdl" ), USP_DRAW_UNSIL, "onehanded" );
		}
		
		float deployTime = 1;
		self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;

		return bResult;
		}
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;
			return;
		}
		
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.14f;
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.217;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.217;
		
		if( g_iCurrentMode == MODE_NOSILENCER )
		{
			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		}
		else if ( g_iCurrentMode == MODE_SILENCER )
		{
			m_pPlayer.m_iWeaponVolume = 0;
			m_pPlayer.m_iWeaponFlash = 0;
		}
		
		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		if ( g_iCurrentMode == MODE_SILENCER )
		{
			if ( self.m_iClip <= 0 )
			{
				self.SendWeaponAnim( USP_SHOOTLAST, 0, 0 );
			}
			else
			{
				switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
				{
					case 0: self.SendWeaponAnim( USP_SHOOT1, 0, 0 ); break;
					case 1: self.SendWeaponAnim( USP_SHOOT2, 0, 0 ); break;
					case 2: self.SendWeaponAnim( USP_SHOOT3, 0, 0 ); break;
				}
			}
		}
		else if ( g_iCurrentMode == MODE_NOSILENCER )
		{
			if ( self.m_iClip <= 0 )
			{
				self.SendWeaponAnim( USP_SHOOTLAST_UNSIL, 0, 0 );
			}
			else
			{
				switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) )
				{
					case 0: self.SendWeaponAnim( USP_SHOOT1_UNSIL, 0, 0 ); break;
					case 1: self.SendWeaponAnim( USP_SHOOT2_UNSIL, 0, 0 ); break;
					case 2: self.SendWeaponAnim( USP_SHOOT3_UNSIL, 0, 0 ); break;
				}
			}
		}
		
		if ( g_iCurrentMode == MODE_SILENCER )
		{
			switch ( Math.RandomLong (0, 1) )
			{
				case 0: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/p228_fire_sil.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM ); break;
				case 1: g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/p228_fire_sil.ogg", 0.9, ATTN_NORM, 0, PITCH_NORM ); break;
			}
		}
		else if ( g_iCurrentMode == MODE_NOSILENCER )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "rng/kuilu/weapons/p228_fire.ogg", 1.0, ATTN_NORM, 0, PITCH_NORM );
		}
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		int m_iBulletDamage = 40;
		
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );

		//self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.15f;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;

		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
		
		TraceResult tr;
		
		float x, y;
		
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
						+ x * VECTOR_CONE_2DEGREES.x * g_Engine.v_right 
						+ y * VECTOR_CONE_2DEGREES.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 4096;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
			}
		}
		Vector vecShellVelocity, vecShellOrigin;
       
		//The last 3 parameters are unique for each weapon (this should be using an attachment in the model to get the correct position, but most models don't have that).
		GetDefaultShellInfo( m_pPlayer, vecShellVelocity, vecShellOrigin, 16, 7, -6 );
       
		//Lefthanded weapon, so invert the Y axis velocity to match.
		vecShellVelocity.y *= 1;
       
		g_EntityFuncs.EjectBrass( vecShellOrigin, vecShellVelocity, m_pPlayer.pev.angles[ 1 ], m_iShell, TE_BOUNCE_SHELL );
	}

	void SecondaryAttack()
	{
		self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 3.135f;
		switch ( g_iCurrentMode )
		{
			case MODE_NOSILENCER:
			{
				g_iCurrentMode = MODE_SILENCER;
				self.SendWeaponAnim( USP_ADD_SILENCER, 0, 0 );
				break;
			}
			case MODE_SILENCER:
			{
				g_iCurrentMode = MODE_NOSILENCER;
				self.SendWeaponAnim( USP_DETACH_SILENCER, 0, 0 );
				break;
			}
		}
		
	}
	
	void Reload()
	{
		if( self.m_iClip < USP_MAX_CLIP )
			BaseClass.Reload();
		
		if ( g_iCurrentMode == MODE_SILENCER )
		{
			self.DefaultReload( USP_MAX_CLIP, USP_RELOAD, 2.73, 0 );
		}
		else
		{
			self.DefaultReload( USP_MAX_CLIP, USP_RELOAD_UNSIL, 2.73, 0 );
		}
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		int iAnim;
		switch ( Math.RandomLong ( 0, 0 ) )
		{
			case 0:
			if( g_iCurrentMode == MODE_SILENCER )
			{
				iAnim = USP_IDLE; break;
			}
			else
			{
				iAnim = USP_IDLE_UNSIL; break;
			}
		}
		
		self.SendWeaponAnim( iAnim );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetUSPName()
{
	return "weapon_usp";
}

void RegisterUSP()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetUSPName(), GetUSPName() );
	g_ItemRegistry.RegisterWeapon( GetUSPName(), "kuilu", "9mm" );
}

string GetUSPAmmoBoxName()
{
	return "9mm";
}

/*void RegisterUSPAmmoBox()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "USPAmmoBox", GetUSPAmmoBoxName() );
}
*/