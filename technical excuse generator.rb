#!/usr/bin/env ruby

class Array
def random_element
  self[rand(self.size)]
end
end

@words1 = %w{Temporary    Intermittant    Partial 
           Redundant    Total        Multiplexed
           Inherent        Duplicated    Dual-Homed
           Synchronous    Bidirectional    Serial
           Asynchronous    Multiple    Replicated
           Non-Replicated    Unregistered    Non-Specific
           Generic        Migrated    Localised
           Resignalled    Dereferenced    Nullified
           Aborted        Serious        Minor
           Major        Extraneous    Illegal
           Insufficient    Viral        Unsupported
           Outmoded        Legacy        Permanent
           Invalid        Deprecated    Virtual
           Unreportable    Undetermined    Undiagnosable
           Unfiltered    Static        Dynamic
           Delayed        Immediate    Nonfatal
           Fatal        Non-Valid    Unvalidated
           Non-Static    Unreplicatable    Non-Serious};

@words2 = %w{Array        Systems        Hardware
           Software        Firmware    Backplane
           Logic-Subsystem    Integrity    Subsystem
           Memory        Comms        Integrity
           Checksum        Protocol    Parity
           Bus        Timing        Synchronisation
           Topology        Transmission    Reception
           Stack        Framing        Code
           Programming    Peripheral    Environmental
           Loading        Operation    Parameter
           Syntax        Initialisation    Execution
           Resource        Encryption    Decryption
           File        Precondition    Authentication
           Paging        Swapfile    Service
           Gateway        Request        Proxy
           Media        Registry    Configuration
           Metadata        Streaming    Retrieval
           Installation    Library        Handler};

@words3 = %w{Interruption    Destabilisation    Destruction
           Desynchronisation Failure    Dereferencing
           Overflow        Underflow    NMI
           Interrupt    Corruption    Anomoly
           Seizure        Override    Reclock
           Rejection    Invalidation    Halt
           Exhaustion    Infection    Incompatibility
           Timeout        Expiry        Unavailability
           Bug        Condition    Crash
           Dump        Crashdump    Stackdump
           Problem        Lockout};

@words4 = %w{Error        Problem        Warning
           Signal        Flag};

@excuse = []
@excuse << @words1.random_element
@excuse << @words2.random_element
@excuse << @words3.random_element
@excuse << @words4.random_element

puts @excuse.join(' ')