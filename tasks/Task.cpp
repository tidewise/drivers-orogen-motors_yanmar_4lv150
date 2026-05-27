/* Generated from orogen/lib/orogen/templates/tasks/Task.cpp */

#include "Task.hpp"
#include <cstring>
#include <motors_yanmar_4lv150/Helpers.hpp>

using namespace motors_yanmar_4lv150;

Task::Task(std::string const& name)
    : TaskBase(name)
    , m_library(j1939::pgns::getLibrary())
{
}

Task::~Task()
{
}

bool Task::configureHook()
{
    if (! TaskBase::configureHook())
        return false;

    m_receiver = new j1939::Receiver(m_library);
    return true;
}
bool Task::startHook()
{
    if (! TaskBase::startHook())
        return false;
    return true;
}
void Task::updateHook()
{
    TaskBase::updateHook();

    canbus::Message can;
    while (_can_in.read(can) == RTT::NewData) {
        auto pgn_msg = can_common::PGNMessage::fromCAN(can);
        auto state = m_receiver->process(pgn_msg);
        if (state.first >= j1939::MessageState::COMPLETE) {
            m_status.update(state.second);
            m_status.last_received_pgn = state.second.pgn;

            if (state.second.pgn == j1939::pgns::VehicleElectricalPower::ID) {
                auto vep = j1939::pgns::VehicleElectricalPower::fromMessage(state.second);
                _alternator_status.write(toDCSourceStatus(vep));
            }
            if (m_status.isFull()) {
                _status.write(m_status);
            }
        }
    }
}
void Task::errorHook()
{
    TaskBase::errorHook();
}
void Task::stopHook()
{
    TaskBase::stopHook();
}
void Task::cleanupHook()
{
    TaskBase::cleanupHook();
    delete m_receiver;
    m_receiver = nullptr;
}
