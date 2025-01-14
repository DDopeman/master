// this and most of the other weapons' code is taken from
// either the HLSP scripts or the half-life sdk with
// minimal changes

enum q1_AxeAnims {
  AXE_IDLE = 0,
  AXE_ATTACK1,
  AXE_ATTACK2
};

class weapon_qaxe : ScriptBasePlayerWeaponEntity {
  int m_iSwing;
  TraceResult m_trHit;
  uint m_iShootAnim;
  
  void Spawn() {
    Precache();
    g_EntityFuncs.SetModel(self, self.GetW_Model("models/quake1/w_axe.mdl"));
    self.m_iClip = -1;
    self.m_flCustomDmg = self.pev.dmg;
    BaseClass.Spawn();
    self.FallInit();

    self.pev.movetype = MOVETYPE_NONE;
  }

  void Precache() {
    self.PrecacheCustomModels();

    g_SoundSystem.PrecacheSound("quake1/weapon.wav"); 
    g_SoundSystem.PrecacheSound("quake1/weapons/axe_hit.wav");
    g_SoundSystem.PrecacheSound("quake1/weapons/axe.wav");

    g_Game.PrecacheModel("models/quake1/v_axe.mdl");
    g_Game.PrecacheModel("models/quake1/p_axe.mdl");
    g_Game.PrecacheModel("models/quake1/w_axe.mdl");
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iMaxAmmo1 = -1;
    info.iMaxAmmo2 = -1;
    info.iMaxClip = WEAPON_NOCLIP;
    info.iSlot = 0;
    info.iPosition = 10;
    info.iWeight = 0;
    return true;
  }

  bool Deploy() {
    return self.DefaultDeploy(self.GetV_Model("models/quake1/v_axe.mdl"), 
                              self.GetP_Model("models/quake1/p_axe.mdl"), 
                              AXE_IDLE, "crowbar");
  }

  void PrimaryAttack() {
    bool fDidHit = false;
    CBasePlayer@ m_pPlayer = cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); // shitty fix for the FUCKING API CHANGE

    TraceResult tr;

    Math.MakeVectors( m_pPlayer.pev.v_angle );
    Vector vecSrc  = m_pPlayer.GetGunPosition();
    Vector vecEnd  = vecSrc + g_Engine.v_forward * 32;

    g_Utility.TraceLine(vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr);

    if (tr.flFraction >= 1.0) {
      g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
      if (tr.flFraction < 1.0) {
        CBaseEntity@ pHit = g_EntityFuncs.Instance(tr.pHit);
        if (pHit is null || pHit.IsBSPModel())
          g_Utility.FindHullIntersection(vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict());
        vecEnd = tr.vecEndPos;
      }
    }

    if (tr.flFraction >= 1.0) {
      m_iShootAnim = Math.RandomLong(0, 1);
      self.SendWeaponAnim(AXE_ATTACK1 + m_iShootAnim, 0, 0);
      self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
      g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/axe.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong(0, 0xF));
      if (!(m_pPlayer.HasNamedPlayerItem("item_qquad") is null))
        g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "quake1/powerups/quad_s.wav", Math.RandomFloat(0.69, 0.7), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
      m_pPlayer.SetAnimation(PLAYER_ATTACK1); 
    } else {
      // hit
      fDidHit = true;
      
      CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
      m_iShootAnim = Math.RandomLong(0, 1);
      self.SendWeaponAnim(AXE_ATTACK1 + m_iShootAnim, 0, 0);

      // player "shoot" animation
      m_pPlayer.SetAnimation(PLAYER_ATTACK1); 

      float flDamage = 20;
      if (q1_CheckQuad(m_pPlayer)) {
        flDamage *= 4;
        g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_ITEM, "quake1/powerups/quad_s.wav", Math.RandomFloat(0.69, 0.7), ATTN_NORM, 0, 93 + Math.RandomLong(0, 0xf));
      }

      g_WeaponFuncs.ClearMultiDamage();
      pEntity.TraceAttack(m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB);  
      g_WeaponFuncs.ApplyMultiDamage(m_pPlayer.pev, m_pPlayer.pev);

      // play thwack, smack, or dong sound
      float flVol = 1.0;
      bool fHitWorld = true;

      if (pEntity !is null) {
        self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25

        if (pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED) {
          if (pEntity.IsPlayer()) {
            pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
          }
          // play thwack or smack sound
          switch(Math.RandomLong(0, 2)) {
            case 0:
              g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1, ATTN_NORM);
              break;
            case 1:
              g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1, ATTN_NORM);
              break;
            case 2:
              g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/cbar_hitbod3.wav", 1, ATTN_NORM);
              break;
          }
          m_pPlayer.m_iWeaponVolume = 128; 
          if(!pEntity.IsAlive())
            return;
          else
            flVol = 0.1;

          fHitWorld = false;
        }
      }

      // play texture hit sound
      // UNDONE: Calculate the correct point of intersection when we hit with the hull instead of the line

      if(fHitWorld == true) {
        float fvolbar = g_SoundSystem.PlayHitSound(tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR);
        
        self.m_flNextPrimaryAttack = g_Engine.time + 0.5; //0.25
        
        // override the volume here, cause we don't play texture sounds in multiplayer, 
        // and fvolbar is going to be 0 from the above call.

        fvolbar = 1;

        // also play crowbar strike       
        g_SoundSystem.EmitSoundDyn(m_pPlayer.edict(), CHAN_WEAPON, "quake1/weapons/axe_hit.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong(0, 3)); 
      }

      // delay the decal a bit
      m_trHit = tr;
      SetThink(ThinkFunction(this.Smack));
      self.pev.nextthink = g_Engine.time + 0.2;

      m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
    }
  }

  void Smack() {
    g_WeaponFuncs.DecalGunshot(m_trHit, BULLET_PLAYER_CROWBAR);
  }
}

void q1_RegisterWeapon_AXE() {
  g_CustomEntityFuncs.RegisterCustomEntity("weapon_qaxe", "weapon_qaxe");
  g_ItemRegistry.RegisterWeapon("weapon_qaxe", "quake1/weapons");
}
