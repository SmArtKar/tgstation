import { useBackend } from '../backend';
import { Section, Box, Button, LabeledList, Icon } from '../components';
import { COLORS } from '../constants';
import { Window } from '../layouts';

export const CoremeisterMenu = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    cores = [],
  } = data;
  return (
    <Window
      width={700}
      height={500}>
      <Window.Content scrollable>
        {cores.map(core => (
          <Section key={core.ref} title={(
            <Box inline color={core.color}>
              {core.name}
            </Box>
          )} buttons={(
            <>
              <Button
                selected={core.chosen}
                disabled={!core.select_availible && !core.chosen}
                onClick={() => act('select', { ref: core.ref })}
              >{!!core.chosen && ("Current Core") || (!!core.select_availible && ("Select") || (core.select_cooldown))}</Button>
              <Button
                disabled={!data.swap_availible}
                onClick={() => act('eject', { ref: core.ref })}
              >Eject Core</Button>
            </>
          )}>
            <LabeledList>
              <LabeledList.Item label="Effects">
                {core.desc}
              </LabeledList.Item>
              {!!((core.use_minor || core.use_major) && core.chosen) && (
                <LabeledList.Item>
                  {!!core.use_minor &&(
                    <Button
                      disabled={!!core.cooldown}
                      onClick={() => act('minor', { ref: core.ref })}
                    >Minor Use</Button>
                  )}
                  {!!core.use_major &&(
                    <Button
                      disabled={!!core.cooldown}
                      onClick={() => act('major', { ref: core.ref })}
                    >Major Use</Button>
                  )}
                </LabeledList.Item>
              )}
            </LabeledList>
          </Section>
        ))}
      </Window.Content>
    </Window>
  );
};
