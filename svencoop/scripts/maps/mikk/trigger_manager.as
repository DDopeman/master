#include 'as_register'

namespace trigger_manager
{
    void MapInit()
    {
        m_EntityFuncs.CustomEntity( 'trigger_manager' );

        m_ScriptInfo.SetScriptInfo
        (
            {
                { 'script', 'trigger_manager' },
                { 'description', 'Allows mapper to fully customize the Triggering-System\'s inputs' }
            }
        )
    }

    enum trigger_manager_spawnflags
    {
        ONCE_PER_PLAYER = 1,
    }

    enum trigger_manager_usetype
    {
        TRIGGER_OFF = 0,
        TRIGGER_ON = 1,
        TRIGGER_KILL = 2,
        TRIGGER_TOGGLE = 3,
        TRIGGER_SAME = 4,
        TRIGGER_OPPOSITE = 5,
        TRIGGER_SET = 6
    }

    class trigger_manager : ScriptBaseEntity, ScriptBaseCustomEntity
    {
        private EHandle h_Activator = null;
        private EHandle = h_Caller = null;
        private float m_iWaitUntilRefire;
        private string m_iszFireOnLocked;
        private string m_iszActivator;
        private string m_iszCaller;
        private bool Reactivated = true;

        bool KeyValue( const string& in szKey, const string& in szValue )
        {
            ExtraKeyValues( szKey, szValue );
            if( szKey == "m_iszActivator" )
            {
                m_iszActivator = szValue;
            }
            else if( szKey == "m_iszCaller" )
            {
                m_iszCaller = szValue;
            }
            else if( szKey == "m_iszFireOnLocked" )
            {
                m_iszFireOnLocked = szValue;
            }
            else if( szKey == "m_iWaitUntilRefire" || szKey == "wait" )
            {
                m_iWaitUntilRefire = atof( szValue );
            }
            else
            {
                return BaseClass.KeyValue( szKey, szValue );
            }
            return true;
        }

        void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
        {
            if( IsLockedByMaster() )
            {
                return;
            }

            // Set new activator
            if( m_iszActivator == '!activator' && pActivator !is null )
            {
                h_Activator = pActivator;
            }
            else if( m_iszActivator.IsEmpty() && pActivator !is null )
            {
                h_Activator = pActivator;
            }
            else if( m_iszActivator == "!caller" && pCaller !is null )
            {
                h_Activator = pCaller;
            }
            else if( m_iszActivator == "!attacker" && pActivator !is null )
            {
                h_Activator = g_EntityFuncs.Instance( pActivator.pev.dmg_inflictor );
            }
            else if( m_iszActivator == "!enemy" && pActivator !is null )
            {
                h_Activator = g_EntityFuncs.Instance( pActivator.pev.enemy );
            }
            else if( m_iszActivator == "!owner" && pActivator !is null )
            {
                h_Activator = g_EntityFuncs.Instance( pActivator.pev.owner );
            }
            else if( !m_iszActivator.IsEmpty() && m_iszActivator != "!self" )
            {
                h_Activator = g_EntityFuncs.FindEntityByTargetname( null, m_iszActivator );
            }
            else
            {
                h_Activator = self;
            }

            // Set new caller
            if( m_iszCaller == '!activator' && pActivator !is null )
            {
                h_Caller = pActivator;
            }
            else if( m_iszCaller.IsEmpty() && pCaller !is null )
            {
                h_Caller = pCaller;
            }
            else if( m_iszCaller == "!caller" && pCaller !is null )
            {
                h_Caller = pCaller;
            }
            else if( m_iszCaller == "!attacker" && pActivator !is null )
            {
                h_Caller = g_EntityFuncs.Instance( pActivator.pev.dmg_inflictor );
            }
            else if( m_iszCaller == "!enemy" && pActivator !is null )
            {
                h_Caller = g_EntityFuncs.Instance( pActivator.pev.enemy );
            }
            else if( m_iszCaller == "!owner" && pActivator !is null )
            {
                h_Caller = g_EntityFuncs.Instance( pActivator.pev.owner );
            }
            else if( !m_iszCaller.IsEmpty() && m_iszCaller != "!self" )
            {
                h_Caller = g_EntityFuncs.FindEntityByTargetname( null, m_iszCaller );
            }
            else
            {
                h_Caller = self;
            }

            int HasFiredThisEntity;
            m_CustomKeyValue.GetValue( h_Activator.GetEntity(), '$i_trigger_manager_once_' + self.entindex(), HasFiredThisEntity );

            if( spawnflag( ONCE_PER_PLAYER ) and HasFiredThisEntity == 1 )
            {
                return;
            }

            m_EntityFuncs.Trigger( ( !Reactivated ? m_iszFireOnLocked : self.pev.target ), h_Activator.GetEntity(), h_Caller.GetEntity(), itout( m_iUseType, useType ), m_fDelay );

            if( Reactivated )
            {
                if( spawnflag( ONCE_PER_PLAYER ) )
                {
                    m_CustomKeyValue.SetValue( h_Activator.GetEntity(), '$i_trigger_manager_once_' + self.entindex(), 1 );
                }
                
                if( m_iWaitUntilRefire > 0.0 )
                {
                    Reactivated = false;
                    g_Scheduler.SetTimeout( @this, "ReActivation", m_iWaitUntilRefire );
                }
            }
        }

        void ReActivation()
        {
            Reactivated = true;
        }
    }
}
