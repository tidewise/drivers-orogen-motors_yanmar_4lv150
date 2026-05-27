/* Generated from orogen/lib/orogen/templates/tasks/Task.hpp */

#ifndef MOTORS_YANMAR_4LV150_TASK_TASK_HPP
#define MOTORS_YANMAR_4LV150_TASK_TASK_HPP

#include "motors_yanmar_4lv150/TaskBase.hpp"
#include <can_common/PGNLibrary.hpp>
#include <can_common/PGNMessage.hpp>
#include <j1939/PGNs.hpp>
#include <j1939/Receiver.hpp>
#include <motors_yanmar_4lv150/Yanmar4LV150Status.hpp>

namespace motors_yanmar_4lv150 {

    class Task : public TaskBase {
        friend class TaskBase;

    protected:
        Yanmar4LV150Status m_status;
        can_common::PGNLibrary m_library;
        j1939::Receiver* m_receiver = nullptr;

    public:
        Task(std::string const& name = "motors_yanmar_4lv150::Task");

        ~Task();

        bool configureHook();

        bool startHook();

        void updateHook();

        void errorHook();

        void stopHook();

        void cleanupHook();
    };
}

#endif